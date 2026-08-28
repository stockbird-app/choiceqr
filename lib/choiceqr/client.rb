require "faraday"
require "faraday/retry"
require "json"
require "securerandom"

module ChoiceQR
  # Entry point for all API interactions.
  #
  # Usage:
  #   client = ChoiceQR::Client.new(token: "your_token")
  #
  #   place = client.place.get
  #   sections = client.sections.list
  #   client.dishes.create(name: "Cappuccino", category: category_id, price: 420)
  #
  #   # Most menu/location endpoints accept a per-call language override; the
  #   # client's default_language ("en" unless configured otherwise) is used
  #   # when omitted.
  #   client.sections.list(language: "de")
  #
  # See ChoiceQR::Client.exchange_token for obtaining a +token+ in the first
  # place, and https://open-api.choiceqr.com/docs/content/authorization for
  # the full OAuth flow.
  class Client
    API_BASE_URL = "https://open-api.choiceqr.com/".freeze

    # Maps HTTP error status codes to [ErrorClass, default_message] pairs.
    ERROR_MAP = {
      400 => [ValidationError, "Bad request"],
      401 => [AuthenticationError, "Missing or invalid token"],
      403 => [ForbiddenError, "Insufficient rights"],
      404 => [NotFoundError, "Resource not found"],
      429 => [RateLimitError, "Rate limit exceeded"],
    }.freeze

    attr_reader :default_language

    # @param token           [String]  long-lived access token obtained via the OAuth flow
    #                                  (see .exchange_token). Valid for ~5 years.
    # @param default_language [String] default :language path segment for menu/location calls (default: "en")
    # @param timeout          [Integer] read timeout in seconds (default: 30)
    # @param open_timeout     [Integer] connection timeout in seconds (default: 5)
    # @param logger           [Logger, nil] optional logger; receives request/response details
    def initialize(token:, default_language: "en", timeout: 30, open_timeout: 5, logger: nil)
      @token             = token
      @default_language  = default_language.to_s
      @timeout           = timeout
      @open_timeout      = open_timeout
      @logger            = logger
    end

    def place
      @place ||= Resources::Place.new(self)
    end

    def section_info
      @section_info ||= Resources::SectionInfo.new(self)
    end

    def sections
      @sections ||= Resources::Sections.new(self)
    end

    def categories
      @categories ||= Resources::Categories.new(self)
    end

    def dishes
      @dishes ||= Resources::Dishes.new(self)
    end

    def dish_options
      @dish_options ||= Resources::DishOptions.new(self)
    end

    def dish_labels
      @dish_labels ||= Resources::DishLabels.new(self)
    end

    def pack
      @pack ||= Resources::Pack.new(self)
    end

    def cutlery
      @cutlery ||= Resources::Cutlery.new(self)
    end

    def full_menu
      @full_menu ||= Resources::FullMenu.new(self)
    end

    def areas
      @areas ||= Resources::Areas.new(self)
    end

    def location_points
      @location_points ||= Resources::LocationPoints.new(self)
    end

    def orders
      @orders ||= Resources::Orders.new(self)
    end

    def bookings
      @bookings ||= Resources::Bookings.new(self)
    end

    def feedbacks
      @feedbacks ||= Resources::Feedbacks.new(self)
    end

    # Exchanges the authorization +code+ obtained from the "Ask permission"
    # redirect for a long-lived access token. This is a one-time setup step;
    # store the returned token and pass it to .new as +token:+.
    #
    #   result = ChoiceQR::Client.exchange_token(code: code, client_id: client_id, secret: secret)
    #   result.token       # => access token, valid ~5 years
    #   result.var_symbol  # => uniq company identifier
    #   result.domain      # => company domain
    #
    # See https://open-api.choiceqr.com/docs/content/authorization
    def self.exchange_token(code:, client_id:, secret:, timeout: 30, open_timeout: 5)
      response = post_token_request(code: code, client_id: client_id, secret: secret,
                                    timeout: timeout, open_timeout: open_timeout)

      unless response.success?
        raise AuthenticationError.new(
          "Failed to exchange code for a token",
          http_status: response.status,
          http_body: response.body
        )
      end

      Resource.new(JSON.parse(response.body))
    end

    def self.post_token_request(code:, client_id:, secret:, timeout:, open_timeout:)
      connection = Faraday.new(url: API_BASE_URL) do |f|
        f.options.timeout      = timeout
        f.options.open_timeout = open_timeout
        f.adapter Faraday.default_adapter
      end

      connection.post("auth/connect/token") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = JSON.generate(code: code, clientId: client_id, secret: secret)
      end
    end
    private_class_method :post_token_request

    # Makes an authenticated HTTP request. Used internally by the resource
    # wrapper classes (client.sections, client.orders, …).
    #
    # @param method  [Symbol]  :get, :post, :put, :patch, :delete
    # @param path    [String]  path relative to API_BASE_URL (e.g. "menu/en/sections/list")
    # @param params  [Hash]    query parameters
    # @param body    [Hash, Array, nil] request body (will be JSON-encoded)
    # @param headers [Hash]    additional request headers
    # @return [Hash] { body: parsed_response }
    def request(method, path, params: {}, body: nil, headers: {})
      response = execute_request(method, path, params: params, body: body, headers: headers)
      handle_response(response)
    end

    private

    def execute_request(method, path, params:, body:, headers:)
      connection.run_request(method, path, body&.to_json, request_headers(headers)) do |req|
        req.params = params unless params.empty?
      end
    rescue Faraday::ConnectionFailed => e
      raise ChoiceQR::ConnectionError, e.message
    rescue Faraday::TimeoutError => e
      raise ChoiceQR::TimeoutError, e.message
    end

    def handle_response(response)
      body = parse_body(response.body)

      return { body: body } if (200..299).cover?(response.status)

      raise_error_for(response, body)
    end

    def raise_error_for(response, body)
      klass, default_msg = ERROR_MAP[response.status]
      klass       ||= response.status >= 500 ? ServerError : Error
      default_msg ||= response.status >= 500 ? "Server error" : "Unexpected status #{response.status}"

      raise klass.new(
        error_message(body, default_msg),
        http_status: response.status,
        http_body: response.body,
        http_headers: response.headers,
        error_name: body.is_a?(Hash) ? body["name"] : nil
      )
    end

    def connection
      @connection ||= Faraday.new(url: API_BASE_URL) do |f|
        f.options.timeout      = @timeout
        f.options.open_timeout = @open_timeout
        # The API documents a 60 req/sec rate limit (some endpoints are
        # stricter — see individual resource methods) and returns 429 when
        # exceeded; back off and retry a couple of times before giving up.
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                          retry_statuses: [429, 500, 502, 503, 504],
                          exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS
        f.request :logger, @logger, headers: false, bodies: false if @logger
        f.adapter Faraday.default_adapter
      end
    end

    def request_headers(extra = {})
      {
        "Authorization" => "Bearer #{@token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        # Lets the API de-duplicate a request that is retried after a
        # network/timeout issue instead of processing it twice.
        "x-idempotence-key" => SecureRandom.uuid,
        "User-Agent" => "choiceqr-ruby/#{ChoiceQR::VERSION} ruby/#{RUBY_VERSION}",
      }.merge(extra)
    end

    def parse_body(body)
      return nil if body.nil? || body.empty?

      JSON.parse(body, symbolize_names: false)
    rescue JSON::ParserError
      body
    end

    def error_message(parsed_body, fallback)
      return fallback unless parsed_body.is_a?(Hash)

      parsed_body["message"] || fallback
    end
  end
end
