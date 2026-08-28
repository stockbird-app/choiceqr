module ChoiceQR
  module Resources
    # Menu items.
    #
    #   client.dishes.list(category_id)
    #   client.dishes.find_by_pos_id("b9e8db61")
    #   client.dishes.create(name: "Cappuccino", category: category_id, price: 420)
    #   client.dishes.update(id, name: "Double Espresso", price: 450)
    #   client.dishes.patch(id, active: false)
    #   client.dishes.update_areas(id, takeaway: true, delivery: false)
    #   client.dishes.set_position(category_id, [id1, id2])
    #   client.dishes.delete(id)
    class Dishes < Base
      def list(category_id, language: nil)
        fetch_list("menu/#{lang(language)}/dishes/list/#{category_id}")
      end

      # Looks a dish up by the posID assigned in your own POS system.
      def find_by_pos_id(pos_id, language: nil)
        fetch_one("menu/#{lang(language)}/dishes", params: { pos_id: pos_id })
      end

      def get(id, language: nil)
        fetch_one("menu/#{lang(language)}/dishes/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("menu/#{lang(language)}/dishes", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "menu/#{lang(language)}/dishes/#{id}", body: attributes)
      end

      # PATCH — partial update of only the given fields.
      def patch(id, language: nil, **attributes)
        mutate(:patch, "menu/#{lang(language)}/dishes/#{id}", body: attributes)
      end

      # Updates which areas (takeaway/delivery/dine-in/digital menu) the dish
      # is available in.
      def update_areas(id, language: nil, **areas)
        mutate(:put, "menu/#{lang(language)}/dishes/#{id}/areas", body: areas)
      end

      # Reorders dishes within +category_id+. +ids+ is the full, ordered
      # array of dish IDs.
      def set_position(category_id, ids, language: nil)
        mutate(:post, "menu/#{lang(language)}/dishes/#{category_id}/position/bulk", body: ids)
      end

      def delete(id, language: nil)
        destroy("menu/#{lang(language)}/dishes/#{id}")
      end
    end
  end
end
