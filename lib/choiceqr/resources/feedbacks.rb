module ChoiceQR
  module Resources
    # Customer feedback for orders and the restaurant in general.
    #
    #   client.feedbacks.list(type: "ORDER")
    #   client.feedbacks.get(id)
    #   client.feedbacks.create(
    #     ref_id: order_id,
    #     feedback: { type: "ORDER", rate_serve: 5, rate_dish: 4, language: "en" },
    #     customer: { name: "John Doe", phone: "+380501234567" }
    #   )
    class Feedbacks < Base
      def list(from: nil, to: nil, limit: nil, offset: nil, type: nil, sort: nil)
        fetch_list("feedbacks", params: {
                     from: format_time(from), to: format_time(to),
                     limit: limit, offset: offset, type: type, sort: sort
                   })
      end

      def get(id)
        fetch_one("feedbacks/#{id}")
      end

      # Rate limit: 1 request / 10 seconds.
      def create(**attributes)
        post_create("feedbacks", attributes)
      end
    end
  end
end
