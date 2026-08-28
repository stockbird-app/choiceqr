module ChoiceQR
  module Resources
    # Information about the place (restaurant, cafe) the client's token
    # belongs to.
    #
    #   client.place.get   # => Resource
    class Place < Base
      def get
        fetch_one("place")
      end
    end
  end
end
