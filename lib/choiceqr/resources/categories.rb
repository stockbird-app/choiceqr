module ChoiceQR
  module Resources
    # Groupings of dishes within a section.
    #
    #   client.categories.list(section_id)
    #   client.categories.create(name: "Hot", section: section_id)
    #   client.categories.update(id, name: "Cold")
    #   client.categories.set_position(section_id, [id1, id2])
    #   client.categories.delete(id)
    class Categories < Base
      def list(section_id, language: nil)
        fetch_list("menu/#{lang(language)}/categories/list/#{section_id}")
      end

      def get(id, language: nil)
        fetch_one("menu/#{lang(language)}/categories/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("menu/#{lang(language)}/categories", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/categories/#{id}", body: attributes)
      end

      # Reorders categories within +section_id+. +ids+ is the full, ordered
      # array of category IDs.
      def set_position(section_id, ids, language: nil)
        mutate(:post, "menu/#{lang(language)}/categories/#{section_id}/position/bulk", body: ids)
      end

      def delete(id, language: nil)
        destroy("menu/#{lang(language)}/categories/#{id}")
      end
    end
  end
end
