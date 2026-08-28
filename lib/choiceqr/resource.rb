module ChoiceQR
  # Generic response object representing any API entity (dish, order, area, …).
  #
  # All keys are snake_case symbols. Attribute access is available via:
  #   - Dot notation:   resource.total_price
  #   - Hash notation:  resource[:total_price]
  #   - Plain hash:     resource.to_h
  #
  # Unlike the top level, ChoiceQR schemas are deeply nested (a dish carries
  # menu options, which carry option list items; an order carries items,
  # which carry modifiers, etc.) and the API has no `include`-style flag to
  # opt in or out of them. So every nested Hash — at any depth — is wrapped
  # as a Resource too, and every nested Array of Hashes becomes an Array of
  # Resource, giving dot access all the way down.
  class Resource
    # +attributes+ is nil for a 200/201 response with an empty body, which
    # the API returns for a handful of endpoints.
    def initialize(attributes)
      # Only this level's keys need converting: #wrap recurses into
      # Resource.new for every nested Hash, which converts its own keys in
      # turn. Pre-converting the whole tree here (e.g. via
      # KeyTransformer.to_snake) would redo that work once per ancestor for
      # every nested node.
      @attributes = (attributes || {}).transform_keys { |k| KeyTransformer.snake_key(k) }
                                      .transform_values { |v| self.class.wrap(v) }
    end

    # Wraps a single value: Hash → Resource, Array → Array of wrapped values,
    # anything else is returned unchanged.
    def self.wrap(value)
      case value
      when Hash  then new(value)
      when Array then value.map { |v| wrap(v) }
      else value
      end
    end

    # Hash-style access with either symbol or string key.
    def [](key)
      @attributes[KeyTransformer.snake_key(key)]
    end

    # Returns a plain snake_case-keyed hash (deep copy, nested Resources
    # unwrapped back to Hash).
    def to_h
      deep_dup(@attributes)
    end

    def inspect
      "#<#{self.class.name} #{@attributes.inspect}>"
    end

    def to_s
      inspect
    end

    def ==(other)
      other.is_a?(Resource) && other.to_h == to_h
    end

    def respond_to_missing?(name, include_private = false)
      @attributes.key?(name) || super
    end

    def method_missing(name, *args)
      if @attributes.key?(name)
        @attributes[name]
      else
        super
      end
    end

    private

    def deep_dup(obj)
      case obj
      when Resource then obj.to_h
      when Hash     then obj.transform_values { |v| deep_dup(v) }
      when Array    then obj.map { |v| deep_dup(v) }
      else obj
      end
    end
  end
end
