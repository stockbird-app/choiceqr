module ChoiceQR
  module Resources
    # Individual points within an area (tables, kiosks, rooms).
    #
    #   client.location_points.list(area_id)
    #   client.location_points.create(name: "Table 4", area: area_id)
    #   client.location_points.delete(id)
    class LocationPoints < Base
      def list(area_id, language: nil)
        fetch_list("location/#{lang(language)}/points/list/#{area_id}")
      end

      def get(id, language: nil)
        fetch_one("location/#{lang(language)}/points/#{id}")
      end

      def create(language: nil, **attributes)
        post_create("location/#{lang(language)}/points", attributes)
      end

      # PUT — full replace. Returns true on success.
      def update(id, language: nil, **attributes)
        mutate(:put, "location/#{lang(language)}/points/#{id}", body: attributes)
      end

      def delete(id, language: nil)
        destroy("location/#{lang(language)}/points/#{id}")
      end
    end
  end
end
