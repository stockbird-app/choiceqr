module ChoiceQR
  module Resources
    # Table bookings/reservations.
    #
    #   client.bookings.list(from: Time.now, till: Time.now + 86_400 * 7)
    #   client.bookings.get(id)
    #   client.bookings.confirm(id, location_points: [point_id])
    #   client.bookings.cancel(id, cancel_reason: "Table no longer available")
    class Bookings < Base
      # Rate limit: 1 request / 5 seconds.
      def list(from: nil, till: nil, period_field: nil, page: nil, per_page: nil)
        fetch_list("bookings/list", params: {
                     from: format_time(from), till: format_time(till),
                     period_field: period_field, page: page, per_page: per_page
                   })
      end

      def get(id)
        fetch_one("bookings/#{id}")
      end

      # Only allowed while the booking status is created.
      def confirm(id, location_points: nil)
        mutate(:put, "bookings/#{id}/confirm", body: { location_points: location_points }.compact)
      end

      def cancel(id, cancel_reason:)
        mutate(:put, "bookings/#{id}/cancel", body: { cancel_reason: cancel_reason })
      end
    end
  end
end
