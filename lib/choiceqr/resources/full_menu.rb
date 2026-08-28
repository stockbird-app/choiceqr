module ChoiceQR
  module Resources
    # Whole-menu operations: fetching the full client menu in one call,
    # bulk import/replace, availability sync, and marketplace data sync.
    #
    #   client.full_menu.list
    #   client.full_menu.import(sections: [...], categories: [...], dishes: [...])
    #   client.full_menu.patch_dishes(dishes: [...])
    #   client.full_menu.sync_availability(dishes: [{ pos_id: "525", active: false }])
    #   client.full_menu.sync_chain_availability(sections: [...])
    #   client.full_menu.sync_marketplace_data(dishes: [{ pos_id: "1", data: { WOLT: { price: 1000 } } }])
    #   client.full_menu.marketplace_sync_status(sync_id)
    class FullMenu < Base
      def list(language: nil)
        fetch_one("menu/#{lang(language)}/full/list")
      end

      # Full replace of the menu (sections:, categories:, dishes:, dish_options:).
      # By default, entities missing from the payload are deleted; pass
      # preserve_missing_items: true to keep them (marked inactive) instead.
      def import(language: nil, preserve_missing_items: nil, **payload)
        mutate(:post, "menu/#{lang(language)}/full", body: payload,
                                                     params: { preserve_missing_items: preserve_missing_items })
      end

      # Partial update of only dish data (dishes:), matched by posID.
      def patch_dishes(language: nil, **payload)
        mutate(:patch, "menu/#{lang(language)}/full/dishes", body: payload)
      end

      # Bulk-updates active/attribute state for sections:, categories:,
      # dishes:, and dish_options:, matched by posID. At least one of these
      # keys must be present.
      def sync_availability(language: nil, skip_missing: nil, **payload)
        mutate(:post, "menu/#{lang(language)}/full/availability", body: payload,
                                                                  params: { skip_missing: skip_missing })
      end

      # Same as #sync_availability, but per chain branch.
      def sync_chain_availability(language: nil, **payload)
        mutate(:post, "menu/#{lang(language)}/full/chain/availability", body: payload)
      end

      # Kicks off an async sync of marketplace-specific price/name overrides.
      # Returns a Resource with the sync job +id+; poll it via
      # #marketplace_sync_status.
      def sync_marketplace_data(dishes:, language: nil)
        post_create("menu/#{lang(language)}/full/marketplace/data", { dishes: dishes })
      end

      def marketplace_sync_status(sync_id, language: nil)
        fetch_one("menu/#{lang(language)}/full/marketplace/data/status/#{sync_id}")
      end
    end
  end
end
