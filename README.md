# choiceqr

Ruby API client for the [ChoiceQR Open API](https://open-api.choiceqr.com/docs#/).

Handles authentication and provides a clean interface to the place, menu, location, order, booking, and feedback resources. Built by [Stockbird](https://stockbird.app).

## Installation

Add to your Gemfile:

```ruby
gem "choiceqr"
```

Or install directly:

```sh
gem install choiceqr
```

## Requirements

- Ruby >= 3.3.0
- A ChoiceQR application and access token obtained via the [ChoiceQR OAuth flow](https://open-api.choiceqr.com/docs/content/authorization) — contact api@choiceqr.com to register.

## Quick start

```ruby
client = ChoiceQR::Client.new(token: ENV["CHOICEQR_TOKEN"])

place = client.place.get
puts place.name

sections = client.sections.list
sections.each { |section| puts section.name }
```

## Authentication

ChoiceQR access tokens are obtained once via an OAuth-style authorization code flow and are valid for roughly five years — there is no refresh step to manage at runtime. Once you have the `code` from the "Ask permission" redirect, exchange it for a token:

```ruby
result = ChoiceQR::Client.exchange_token(code: code, client_id: client_id, secret: secret)
result.token       # => access token, valid ~5 years — store this securely
result.var_symbol  # => uniq company identifier
result.domain      # => company domain

client = ChoiceQR::Client.new(token: result.token)
```

See [Authorization](https://open-api.choiceqr.com/docs/content/authorization) for the full flow (connecting your application to a client, permission dialog, callback URL).

## Resources

The following resource accessors are available on the client:

| Method | API path |
|---|---|
| `client.place` | `place` |
| `client.section_info` | `menu/:language/section-info/:sectionId` |
| `client.sections` | `menu/:language/sections` |
| `client.categories` | `menu/:language/categories`, scoped by section |
| `client.dishes` | `menu/:language/dishes`, scoped by category |
| `client.dish_options` | `menu/:language/options`, scoped by section |
| `client.dish_labels` | `menu/:language/dish-labels` |
| `client.pack` | `menu/:language/pack` |
| `client.cutlery` | `menu/:language/cutlery` (a single settings object, no id) |
| `client.full_menu` | `menu/:language/full/*` — bulk import, availability sync, marketplace sync |
| `client.areas` | `location/:language/areas` |
| `client.location_points` | `location/:language/points`, scoped by area |
| `client.orders` | `orders` |
| `client.bookings` | `bookings` |
| `client.feedbacks` | `feedbacks` |

Most menu/location methods accept a per-call `language:` override; when omitted, the client's `default_language` (`"en"` unless configured otherwise) is used:

```ruby
client = ChoiceQR::Client.new(token: token, default_language: "de")
client.sections.list                 # uses "de"
client.sections.list(language: "cs") # overrides to "cs" for this call
```

## CRUD operations

Attributes are passed as keyword arguments (or splat a Hash with `**`), not a positional Hash — this matches how most modern Ruby API clients read, and keeps every method's required path arguments (`id`, `section_id`, …) unambiguous from the optional attributes:

```ruby
section = client.sections.create(name: "Drinks", pos_id: "10")
client.sections.update(section.id, name: "Beverages")
client.sections.set_position([id1, id2, id3])
client.sections.delete(section.id)

category = client.categories.create(name: "Hot", section: section.id)
client.categories.list(section.id)

dish = client.dishes.create(name: "Cappuccino", category: category.id, price: 420) # price is in cents
client.dishes.update(dish.id, name: "Double Espresso", price: 450)
client.dishes.patch(dish.id, active: false) # partial update
client.dishes.update_areas(dish.id, takeaway: true, delivery: false)
client.dishes.find_by_pos_id("your-pos-id")
```

`update`/`patch`/position-bulk/attach/detach endpoints return `204 No Content` on success — the corresponding gem methods return `true` rather than a fetched Resource (there's no ETag or similar concurrency token to round-trip). `delete` also returns `true`.

### Full menu import and availability sync

```ruby
client.full_menu.import(
  sections: [{ pos_id: "1", name: "Main" }],
  categories: [{ pos_id: "1", section_pos_id: "1", name: "Hot" }],
  dishes: [{ pos_id: "1", category_pos_id: "1", name: "Coffee", price: 300 }],
  preserve_missing_items: true
)

client.full_menu.sync_availability(dishes: [{ pos_id: "525", active: false }])

sync = client.full_menu.sync_marketplace_data(
  dishes: [{ pos_id: "1", data: { WOLT: { price: 1000, name: "Wolt name" } } }]
)
client.full_menu.marketplace_sync_status(sync.id)
```

### Orders

```ruby
client.orders.list(since: Time.now - 3600, include_approved: true)
client.orders.list_archive(from: Time.now - 86_400 * 30, till: Time.now) # rate limit: 1 req / 5s
order = client.orders.get(id)
client.orders.get_by_guid(order.guid)
client.orders.update_delivery(order.id, delivery_status: "processing")
client.orders.cancel(order.id, reason: "Out of stock")
client.orders.close(order.id)
```

### Bookings

```ruby
client.bookings.list(from: Time.now, till: Time.now + 86_400 * 7) # rate limit: 1 req / 5s
booking = client.bookings.get(id)
client.bookings.confirm(booking.id, location_points: [point_id])
client.bookings.cancel(booking.id, cancel_reason: "Table no longer available")
```

### Feedbacks

```ruby
client.feedbacks.list(type: "ORDER")
client.feedbacks.create(
  ref_id: order_id,
  feedback: { type: "ORDER", rate_serve: 5, rate_dish: 4, language: "en", message: "Great!" },
  customer: { name: "John Doe", phone: "+380501234567" }
) # rate limit: 1 req / 10s
```

## Response objects

All returned data is a `ChoiceQR::Resource` — a generic object backed by a snake_case symbol-keyed hash. Nested data (menu options, order items, etc.) is wrapped the same way at every depth, so dot access works throughout:

```ruby
dish.name                              # dot notation
dish[:name]                            # symbol key
dish["posID"]                          # camelCase string key (also works)
dish.menu_options.first.list.first.price
dish.to_h                              # plain hash, nested Resources unwrapped
```

API keys are transformed as follows:
- `defaultLanguage` → `:default_language`
- `posID` → `:pos_id` (the one field ChoiceQR capitalizes as an acronym instead of plain camelCase)
- `_id` → `:id` (leading underscore stripped)

A field whose name collides with a real `Object` method (`hash`, `method`, `class`, `send`, …) isn't reachable via dot access — Ruby dispatches to the real method first. Use `resource[:hash]`-style hash access for those instead.

## Error handling

All errors inherit from `ChoiceQR::Error` and carry `http_status`, `http_body`, `http_headers`, and `error_name` (the API's own `"ValidationError"`/`"ServiceError"` classification, where present):

```ruby
begin
  client.dishes.get("nonexistent")
rescue ChoiceQR::NotFoundError
  # unknown id
rescue ChoiceQR::AuthenticationError
  # token missing or invalid
rescue ChoiceQR::ForbiddenError
  # token doesn't have the required scope
rescue ChoiceQR::ValidationError => e
  puts e.message
rescue ChoiceQR::RateLimitError
  # 429 — the gem already retries a couple of times with backoff before this is raised
rescue ChoiceQR::ServerError
  # 5xx
rescue ChoiceQR::Error => e
  # catch-all
end
```

Full error hierarchy:

```
ChoiceQR::Error
├── ChoiceQR::ConnectionError
├── ChoiceQR::TimeoutError
└── ChoiceQR::ClientError
    ├── ChoiceQR::ValidationError      (400)
    ├── ChoiceQR::AuthenticationError  (401)
    ├── ChoiceQR::ForbiddenError       (403)
    ├── ChoiceQR::NotFoundError        (404)
    └── ChoiceQR::RateLimitError       (429)
└── ChoiceQR::ServerError              (5xx)
```

## Rate limits

The API documents a general 60 req/sec limit, with some endpoints stricter still (booking/order-archive listing, feedback creation, availability/marketplace sync — see the relevant method's docs above). The gem automatically retries a request up to twice with backoff on `429`/`5xx` responses; persistent rate limiting still raises `ChoiceQR::RateLimitError`. The gem does not otherwise throttle requests client-side — back off in your own code if you're making high-volume calls.

## Configuration

```ruby
client = ChoiceQR::Client.new(
  token: "...",
  default_language: "en", # default: "en"
  timeout: 60,             # read timeout in seconds (default: 30)
  open_timeout: 10,        # connection timeout in seconds (default: 5)
  logger: Logger.new($stdout)
)
```

## Webhooks

ChoiceQR pushes events (menu changes, new orders, booking updates, …) to a Webhook URL you configure when creating your application — there is no API for managing webhook subscriptions, so this gem does not include a webhook client. See [Webhooks](https://open-api.choiceqr.com/docs/content/webhooks) for the event payload shape; the `data` field of each event matches the corresponding resource's response schema, so you can wrap it yourself with `ChoiceQR::Resource.new(event["data"])` if useful.

## Development

```sh
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT — see [LICENSE.md](LICENSE.md).
