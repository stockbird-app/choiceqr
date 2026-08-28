module ChoiceQR
  # Bidirectional key transformation between the API's lowerCamelCase format
  # and Ruby's conventional snake_case.
  #
  # API → Ruby (responses):
  #   "defaultLanguage" → :default_language
  #   "posID"           → :pos_id
  #   "sectionPosID"    → :section_pos_id
  #   "_id"             → :id   (leading underscore stripped)
  #
  # Ruby → API (request bodies):
  #   :default_language → "defaultLanguage"
  #   :pos_id            → "posID"           (see #merge_acronyms below)
  #   :section_pos_id     → "sectionPosID"
  #   :_id                → "_id"    (a leading underscore is preserved, since
  #                                    some payloads reference an existing
  #                                    entity's id this way, e.g. Pack#create
  #                                    categories)
  #
  # Note: "PosID" is the one acronym the ChoiceQR API capitalizes in full
  # instead of following plain camelCase ("Id") — and it shows up both as a
  # standalone field and as a suffix on cross-reference fields (sectionPosID,
  # categoryPosID, …) throughout the whole API, so #camelize special-cases
  # the "pos"+"id" word pair wherever it appears rather than only matching
  # the exact key "posID"/"pos_id".
  module KeyTransformer
    module_function

    # Recursively transforms all keys in a Hash (or Array of Hashes) from the
    # API format to snake_case symbols.
    def to_snake(obj)
      case obj
      when Hash
        obj.transform_keys { |k| snake_key(k) }
           .transform_values { |v| to_snake(v) }
      when Array
        obj.map { |v| to_snake(v) }
      else
        obj
      end
    end

    # Recursively transforms all keys in a Hash (or Array of Hashes) from
    # snake_case symbols/strings to lowerCamelCase strings for API requests.
    def to_camel(obj)
      case obj
      when Hash
        obj.transform_keys { |k| camel_key(k) }
           .transform_values { |v| to_camel(v) }
      when Array
        obj.map { |v| to_camel(v) }
      else
        obj
      end
    end

    # Single key: API string → snake_case symbol
    def snake_key(key)
      key.to_s
         .delete_prefix("_") # strip leading underscore (_id → id)
         .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2') # ABCDef → ABC_def
         .gsub(/([a-z\d])([A-Z])/, '\1_\2') # camelCase → camel_case
         .downcase
         .to_sym
    end

    # Single key: snake_case symbol/string → lowerCamelCase string
    def camel_key(key)
      str    = key.to_s
      prefix = str.start_with?("_") ? "_" : ""
      body   = prefix.empty? ? str : str[1..]

      prefix + camelize(body)
    end

    def camelize(str)
      segments = merge_acronyms(str.split("_"))
      segments[0] + segments[1..].join
    end

    # Joins an adjacent ["pos", "id"] word pair into the API's "posID"/"PosID"
    # acronym spelling instead of capitalizing them individually into
    # "posId"/"PosId". Every other word is capitalized normally, except the
    # very first segment of the key, which is used verbatim (standard
    # camelCase, and how a single-word key like :WOLT survives untouched).
    def merge_acronyms(parts)
      segments = []
      i = 0
      while i < parts.length
        acronym = parts[i] == "pos" && parts[i + 1] == "id"
        segments << next_segment(parts[i], first: segments.empty?, acronym: acronym)
        i += acronym ? 2 : 1
      end
      segments
    end

    def next_segment(word, first:, acronym:)
      return first ? "posID" : "PosID" if acronym

      first ? word : word.capitalize
    end
  end
end
