module ChoiceQR
  module Resources
    # Ordering areas (bar, hall, terrace, takeaway, delivery, digital menu).
    #
    #   client.areas.list
    #   client.areas.get_by_type("takeaway")
    #   client.areas.create(name: "Terrace", payment_methods: { cash: true, card: true })
    #   client.areas.delete(id)
    class Areas < Base
      def list(language: nil)
        fetch_list("location/#{lang(language)}/areas/list")
      end

      def get(id, language: nil)
        fetch_one("location/#{lang(language)}/areas/#{id}")
      end

      # +type+ is one of: takeaway, delivery, simple, digitalMenu
      def get_by_type(type, language: nil)
        fetch_one("location/#{lang(language)}/areas/by-type/#{type}")
      end

      def create(language: nil, **attributes)
        post_create("location/#{lang(language)}/areas", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "location/#{lang(language)}/areas/#{id}", body: attributes)
      end

      def delete(id, language: nil)
        destroy("location/#{lang(language)}/areas/#{id}")
      end
    end
  end
end
