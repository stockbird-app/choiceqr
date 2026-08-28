require "json"

module ChoiceQR
  # Wraps an incoming webhook event payload — the thing your own server
  # receives at the Webhook URL configured for your application (see
  # https://open-api.choiceqr.com/docs/content/application), not something
  # this gem calls the API for. ChoiceQR has no API for managing webhook
  # subscriptions (the URL is set once in the app dashboard), so there is no
  # corresponding client.webhooks resource — this class only parses the
  # payload shape.
  #
  # IMPORTANT: ChoiceQR does not document a signature or secret for
  # verifying that a webhook request genuinely came from ChoiceQR. This
  # class parses the payload; it does not, and cannot, authenticate it.
  #
  # Usage (e.g. inside a Rack/Sinatra/Rails webhook endpoint):
  #
  #   event = ChoiceQR::WebhookEvent.parse(request.body.read)
  #   event.id          # => "unique_id"
  #   event.type        # => "dish.created"
  #   event.lang_code   # => "en"
  #   event.var_symbol  # => company id
  #
  #   case event.type
  #   when "dish.created", "dish.changed"
  #     event.data.name   # data is the same Dish shape #dishes.get returns
  #   when "section.positionChanged"
  #     event.data.items  # => array of section ids
  #   when /\.removed\z/
  #     event.data.id     # => {_id: "..."} → :id
  #   end
  #
  # See https://open-api.choiceqr.com/docs/content/webhooks for the full
  # event type → data shape mapping.
  class WebhookEvent
    # Every event type ChoiceQR documents, for reference — not enforced:
    # #type is whatever string the payload contains, so an event type added
    # to the API later still parses fine here.
    TYPES = %w[
      place.changed
      sectionInfo.changed
      section.created section.changed section.positionChanged section.removed
      category.created category.changed category.positionChanged category.removed
      dish.created dish.changed dish.positionChanged dish.removed
      dishOption.changed
      menuLabel.created menuLabel.changed menuLabel.removed
      option.created option.changed option.positionChanged option.removed
      import.full.done
      marketplace.acceptance.enabled marketplace.acceptance.disabled
      order.created order.accepted order.cancelled order.closed order.delivery.update
      order.qrPayment.completed order.qrPayment.error
    ].freeze

    # +payload+ is a JSON String (e.g. a raw request body) or an
    # already-parsed Hash.
    def self.parse(payload)
      new(payload.is_a?(String) ? JSON.parse(payload) : payload)
    end

    def initialize(attributes)
      @resource = Resource.new(attributes)
    end

    def id
      @resource.id
    end

    # The event type, e.g. "dish.created", "order.qrPayment.completed" — see
    # TYPES.
    def type
      @resource.type
    end

    def lang_code
      @resource.lang_code
    end

    # Uniq identifier of the company the event belongs to.
    def var_symbol
      @resource.var_symbol
    end

    # The event-specific payload. Its shape depends on #type — see the class
    # docs above and https://open-api.choiceqr.com/docs/content/webhooks.
    def data
      @resource.data
    end

    # Hash-style access, for any envelope field not covered by a named
    # reader above.
    def [](key)
      @resource[key]
    end

    def to_h
      @resource.to_h
    end

    def inspect
      "#<#{self.class.name} type=#{type.inspect} id=#{id.inspect}>"
    end

    def to_s
      inspect
    end

    def respond_to_missing?(name, include_private = false)
      @resource.respond_to?(name, include_private) || super
    end

    # Delegates to the underlying Resource, so any envelope field not given
    # a named reader above (or a documented-but-misspelled one) is still
    # reachable by dot access.
    def method_missing(name, *, &)
      if @resource.respond_to?(name)
        @resource.public_send(name, *, &)
      else
        super
      end
    end
  end
end
