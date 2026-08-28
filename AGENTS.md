# AGENTS.md

Guidance for AI agents working in this repository.

## Project overview

This is a Ruby gem (`choiceqr`) — an API client for the [ChoiceQR Open API](https://open-api.choiceqr.com/docs#/). It is maintained by the Stockbird team.

**API documentation:** https://open-api.choiceqr.com/docs#/ — a Docsify site (markdown under `/docs/content/**`, no machine-readable OpenAPI/Swagger spec) and the authoritative source of truth for all endpoint paths, request/response shapes, and authentication flow.

## Repository layout

```
lib/choiceqr/
├── version.rb             # VERSION constant only
├── configuration.rb       # Default timeouts; API_BASE_URL constant (currently unused by Client — see below)
├── errors.rb              # Full error class hierarchy
├── key_transformer.rb     # camelCase ↔ snake_case key conversion (with a posID/_id override — see below)
├── resource.rb            # Generic response object (dot + hash access), recursively wraps nested data
├── resources/
│   ├── base.rb             # Shared request helpers (fetch_one/fetch_list/post_create/mutate/destroy)
│   ├── place.rb             # GET /place
│   ├── section_info.rb      # GET /menu/:language/section-info/:sectionId
│   ├── sections.rb          # /menu/:language/sections
│   ├── categories.rb        # /menu/:language/categories, scoped by sectionId
│   ├── dishes.rb             # /menu/:language/dishes, scoped by categoryId
│   ├── dish_options.rb      # /menu/:language/options, scoped by sectionId
│   ├── dish_labels.rb       # GET /menu/:language/dish-labels/list
│   ├── pack.rb                # /menu/:language/pack
│   ├── cutlery.rb            # /menu/:language/cutlery (singleton)
│   ├── full_menu.rb          # /menu/:language/full/* — bulk import/availability/marketplace sync
│   ├── areas.rb               # /location/:language/areas
│   ├── location_points.rb   # /location/:language/points, scoped by areaId
│   ├── orders.rb              # /orders/*
│   ├── bookings.rb           # /bookings/*
│   └── feedbacks.rb          # /feedbacks/*
└── client.rb               # Public entry point; resource accessors; HTTP guts; .exchange_token

spec/choiceqr/              # RSpec tests (one file per lib file; resources/ mirrors lib/choiceqr/resources/)
spec/spec_helper.rb         # WebMock setup; shared helpers and top-level constants
```

## Development commands

```sh
bundle install             # install dependencies
bundle exec rspec          # run full test suite
bundle exec rspec spec/choiceqr/client_spec.rb  # run a single spec file
bundle exec rubocop        # lint
```

Ruby version is pinned in `.ruby-version` (managed via rbenv).

## Why this gem doesn't look like dotypos

This gem was bootstrapped from [`dotypos`](https://github.com/stockbird-app/dotypos) (another Stockbird API client) and follows its house style: Faraday + a hand-rolled `KeyTransformer`, a generic `Resource` dot-access wrapper, the same error hierarchy shape, RSpec + WebMock, the same `.rubocop.yml`/gemspec/CI conventions. But the two APIs are shaped very differently, which shows up in two structural departures:

- **No single generic `ResourceCollection`.** Dotypos's API is uniform: every resource lives at `clouds/:cloudId/<resource>` and supports the same list/get/create/update/replace/delete verbs. ChoiceQR is not uniform — list scoping differs per resource (`dishes/list/:categoryId` vs `options/list/:sectionId` vs a flat `orders/list`), and available actions differ too (position-bulk, attach/detach, patch-only-dishes, PUT-with-no-body, …). So each resource gets its own small class in `resources/`, all built on the shared `Resources::Base` helpers — the same pattern dotypos itself uses for `CloudCollection`, just applied to every resource instead of the one exception.
- **`Resource` recursively wraps nested data.** Dotypos only wraps a curated whitelist of nested collections (`order_items`, `money_logs`) because its API is otherwise flat and has an opt-in `include` parameter. ChoiceQR has no such flag and its schemas are deeply nested by default (a dish carries `menuOptions`, which carry `list`, an order carries `items`, which carry modifiers, …), so `Resource` wraps every nested Hash/Array-of-Hash at any depth into further `Resource` instances for consistent dot access.

## Key conventions

- **All API keys are snake_case symbols** in Ruby. Conversion happens in `KeyTransformer` — do not apply transformations elsewhere.
- **`posID` is a special-cased acronym.** ChoiceQR capitalizes this one field in full (`posID`, `sectionPosID`, `categoryPosID`, …) instead of plain camelCase (`PosId`), and it shows up both standalone and as a suffix on cross-reference fields throughout the menu/location endpoints. `KeyTransformer#merge_acronyms` handles this by merging an adjacent `["pos", "id"]` word pair wherever it appears in a snake_case key, rather than only matching the exact key `pos_id`. Don't build a general acronym-inflection system beyond this — it's the one real exception in the whole API.
- **A leading underscore is preserved by `camel_key`.** Most payload writes use IDs supplied via the URL path, but a few nested payload objects reference an existing entity by literal `_id` (e.g. `Pack#create` `categories: [{ _id: ... }]`). Pass `:_id` (or `"_id"`) explicitly for those; the top-level `id` read back from a response does not round-trip to `_id` on write (same documented tradeoff dotypos makes for `_cloudId`).
- **Resource methods take `**attributes`, not a positional Hash.** `def create(language: nil, **attributes)`, not `def create(attributes, language: nil)`. Ruby 3 keyword-argument separation means the latter breaks on `create(name: "x")` — there's no positional Hash being passed, only keywords, and Ruby won't auto-collect them. This bit us once already; don't reintroduce a positional-attributes parameter next to real keyword params.
- **No token refresh.** Unlike dotypos's OAuth refresh-token flow, a ChoiceQR access token is valid for ~5 years once obtained via `Client.exchange_token`. There is no `TokenManager` — `Client` just holds a static bearer token.
- **No ETags.** ChoiceQR's PUT/PATCH endpoints don't use `If-Match`/ETag concurrency control; updates return `204 No Content` and the resource wrapper methods return `true`, matching `#delete`'s existing convention rather than fabricating a fetched-and-returned Resource.
- **`Client.new`/`.exchange_token` default their kwargs from `ChoiceQR.configuration`** (`default_language:`, `timeout:`, `open_timeout:`, `logger:`), evaluated per-call since Ruby default-argument expressions run at call time. This is a deliberate departure from dotypos, where the equivalent `Configuration` class exists but is never read by `Client` — that disconnect looked like a bug to an independent review pass here, and `ChoiceQR.configure { |c| c.timeout = 60 }` doing nothing would be a real footgun in a fresh gem. Don't revert to hardcoded literal defaults.
- **The `x-idempotence-key` header is sent on every request** (`SecureRandom.uuid`, generated once per request attempt so retries reuse it) per the API guidelines page. Don't remove it.
- **Faraday's retry middleware is wired up** (`f.request :retry`) for 429/5xx, since the API explicitly documents rate limits per endpoint. Some endpoints have much stricter limits than the general 60 req/sec (e.g. feedback create: 1/10s) — those are called out in the relevant resource method's comment, not enforced client-side.

## Testing

- Tests use **RSpec + WebMock** (no VCR cassettes).
- Shared test constants (`TOKEN`, `API_BASE`) are defined at the **top level** of `spec/spec_helper.rb` — not inside a module — so they are accessible as bare constants in all spec files.
- Every spec that makes HTTP calls should use `build_client` (stubs nothing itself — there's no auth handshake to stub, unlike dotypos).
- Run the full suite before committing; suite run should report no errors.
- Run `rubocop -A` before committing, ensure no unfixed offences remain. Fix as required.

## Dependency policy

- Runtime dependencies are limited to `faraday` and `faraday-retry`. Do not add further runtime dependencies without discussion.
- Development dependencies: `rspec`, `webmock`, `rake`, `rubocop`, `rubocop-rspec`.
