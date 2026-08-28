module ChoiceQR
  module Resources
    # Top-level menu groupings (e.g. "Breakfast", "Drinks").
    #
    #   client.sections.list
    #   client.sections.create(name: "Drinks")
    #   client.sections.update(id, name: "Beverages")
    #   client.sections.set_position([id1, id2, id3])
    #   client.sections.delete(id)
    class Sections < Base
      def list(language: nil)
        fetch_list("menu/#{lang(language)}/sections/list")
      end

      def get(id, language: nil)
        fetch_one("menu/#{lang(language)}/sections/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("menu/#{lang(language)}/sections", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/sections/#{id}", body: attributes)
      end

      # Reorders sections. +ids+ is the full, ordered array of section IDs.
      def set_position(ids, language: nil)
        mutate(:post, "menu/#{lang(language)}/sections/position/bulk", body: ids)
      end

      def delete(id, language: nil)
        destroy("menu/#{lang(language)}/sections/#{id}")
      end
    end
  end
end
