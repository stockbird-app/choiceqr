module ChoiceQR
  module Resources
    # Customer orders (delivery, takeaway, or table).
    #
    #   client.orders.list(since: Time.now - 3600)
    #   client.orders.list_archive(from: Time.now - 86_400 * 30, till: Time.now)
    #   client.orders.get(id)
    #   client.orders.get_by_guid(guid)
    #   client.orders.update_delivery(id, delivery_status: "processing")
    #   client.orders.cancel(id, reason: "Out of stock")
    #   client.orders.close(id)
    class Orders < Base
      def list(since: nil, include_approved: nil, branches: nil, page: nil, per_page: nil)
        fetch_list("orders/list", params: {
                     since: format_time(since), include_approved: include_approved,
                     branches: format_branches(branches), page: page, per_page: per_page
                   })
      end

      # Rate limit: 1 request / 5 seconds.
      def list_archive(from:, till:, branches: nil, page: nil, per_page: nil)
        fetch_list("orders/list/archive", params: {
                     from: format_time(from), till: format_time(till),
                     branches: format_branches(branches), page: page, per_page: per_page
                   })
      end

      def get(id)
        fetch_one("orders/#{id}")
      end

      def get_by_guid(guid)
        fetch_one("orders/guid/#{guid}")
      end

      # Only allowed while the order status is approved or delivery.
      def update_delivery(id, **attributes)
        mutate(:put, "orders/#{id}/delivery", body: attributes)
      end

      # Only allowed while the order status is waiting_for_approve, approved,
      # or delivery.
      def cancel(id, reason:)
        mutate(:put, "orders/#{id}/cancel", body: { reason: reason })
      end

      # Only allowed while the order status is approved or delivery.
      def close(id)
        mutate(:put, "orders/#{id}/close")
      end

      private

      def format_branches(branches)
        Array(branches).join(",") if branches
      end
    end
  end
end
