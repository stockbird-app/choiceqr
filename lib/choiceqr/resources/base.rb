module ChoiceQR
  module Resources
    # Shared plumbing for the per-entity resource wrapper classes reached via
    # the client accessors (client.sections, client.dishes, client.orders, …).
    #
    # ChoiceQR's endpoints are not path-uniform the way Dotypos's are (list
    # scoping, nesting, and available actions differ per resource type), so
    # unlike a single generic ResourceCollection, each entity gets its own
    # small class here that knows its own paths.
    class Base
      def initialize(client)
        @client = client
      end

      private

      attr_reader :client

      # Resolves the :language path segment: an explicit override, or the
      # client's configured default_language.
      def lang(language)
        (language || client.default_language).to_s
      end

      def fetch_one(path, params: {})
        response = client.request(:get, path, params: to_query(params))
        Resource.new(response.fetch(:body))
      end

      def fetch_list(path, params: {})
        response = client.request(:get, path, params: to_query(params))
        Array(response.fetch(:body)).map { |item| Resource.new(item) }
      end

      def post_create(path, attributes, params: {})
        response = client.request(:post, path, body: KeyTransformer.to_camel(attributes), params: to_query(params))
        Resource.new(response.fetch(:body))
      end

      # PUT/PATCH/POST calls that return 204 No Content on success.
      def mutate(method, path, body: nil, params: {})
        client.request(method, path, body: body && KeyTransformer.to_camel(body), params: to_query(params))
        true
      end

      def destroy(path)
        client.request(:delete, path)
        true
      end

      # Query params use camelCase names too (e.g. includeApproved, perPage),
      # same as request bodies.
      def to_query(params)
        KeyTransformer.to_camel(params.compact)
      end

      def format_time(value)
        return nil if value.nil?
        return value.to_s unless value.respond_to?(:iso8601)

        # Time/DateTime#iso8601 take an optional fractional-digits argument;
        # Date#iso8601 (no time component) takes none. Check arity instead of
        # is_a?(Date) so any iso8601-compatible object works, not just those
        # two stdlib classes.
        value.method(:iso8601).arity.zero? ? value.iso8601 : value.iso8601(3)
      end
    end
  end
end
