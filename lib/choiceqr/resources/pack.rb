module ChoiceQR
  module Resources
    # Menu packages (bundles of categories sold together).
    #
    #   client.pack.list
    #   client.pack.create(name: "Lunch set", price: 1000, categories: [{ _id: category_id }])
    #   client.pack.delete(id)
    #
    # Note: entries in the +categories+ payload reference an existing
    # category by its Mongo id. Use the literal key +:_id+ (or the string
    # +"_id"+) — the leading underscore is preserved by the key transformer,
    # unlike the top-level +id+ read from responses.
    class Pack < Base
      def list(language: nil)
        fetch_list("menu/#{lang(language)}/pack/list")
      end

      def get(id, language: nil)
        fetch_one("menu/#{lang(language)}/pack/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("menu/#{lang(language)}/pack", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/pack/#{id}", body: attributes)
      end

      def delete(id, language: nil)
        destroy("menu/#{lang(language)}/pack/#{id}")
      end
    end
  end
end
