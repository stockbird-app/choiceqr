module ChoiceQR
  # Base error — callers can rescue ChoiceQR::Error to catch everything.
  class Error < StandardError
    attr_reader :http_status, :http_body, :http_headers, :error_name

    def initialize(msg = nil, http_status: nil, http_body: nil, http_headers: nil, error_name: nil)
      super(msg)
      @http_status  = http_status
      @http_body    = http_body
      @http_headers = http_headers
      @error_name   = error_name
    end

    def to_s
      http_status ? "(HTTP #{http_status}) #{super}" : super
    end
  end

  # Network-level errors
  class ConnectionError < Error; end
  class TimeoutError    < Error; end

  # 4xx client errors
  class ClientError         < Error; end
  # 400 — the API calls this "ValidationError" or "ServiceError"
  class ValidationError     < ClientError; end
  # 401 — missing or invalid token
  class AuthenticationError < ClientError; end
  # 403 — token does not have the required scope/rights
  class ForbiddenError      < ClientError; end
  # 404 — not documented in the API guidelines, but returned for unknown IDs
  class NotFoundError       < ClientError; end
  # 429
  class RateLimitError      < ClientError; end

  # 5xx server errors
  class ServerError < Error; end
end
