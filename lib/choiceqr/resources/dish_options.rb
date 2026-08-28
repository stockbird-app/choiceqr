module ChoiceQR
  module Resources
    # Customizable dish options (single/multiple choice modifiers), shared
    # across the dishes they are attached to.
    #
    #   client.dish_options.list(section_id)
    #   client.dish_options.create(name: "Size", type: "single", section: section_id)
    #   client.dish_options.attach(option_id, dish_id)
    #   client.dish_options.detach(option_id, dish_id)
    #   client.dish_options.delete(id)
    class DishOptions < Base
      def list(section_id, language: nil)
        fetch_list("menu/#{lang(language)}/options/list/#{section_id}")
      end

      def get(id, language: nil)
        fetch_one("menu/#{lang(language)}/options/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("menu/#{lang(language)}/options", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/options/#{id}", body: attributes)
      end

      # Reorders options within +section_id+. +ids+ is the full, ordered
      # array of option IDs.
      def set_position(section_id, ids, language: nil)
        mutate(:post, "menu/#{lang(language)}/options/#{section_id}/position/bulk", body: ids)
      end

      def delete(id, language: nil)
        destroy("menu/#{lang(language)}/options/#{id}")
      end

      def attach(id, dish_id, language: nil)
        mutate(:put, "menu/#{lang(language)}/options/#{id}/attach", body: { dish: dish_id })
      end

      def detach(id, dish_id, language: nil)
        mutate(:put, "menu/#{lang(language)}/options/#{id}/detach", body: { dish: dish_id })
      end
    end
  end
end
