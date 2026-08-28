# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-08-29

### Added

- `ChoiceQR::WebhookEvent` — parses an incoming webhook payload (`.parse` accepts a raw JSON string or an already-parsed Hash) into the envelope fields (`id`, `type`, `lang_code`, `var_symbol`) plus a `data` accessor that reuses `ChoiceQR::Resource`'s recursive wrapping, so `event.data` reads like the matching resource method's return value regardless of event type. `ChoiceQR::WebhookEvent::TYPES` lists every documented event type for reference (not enforced). ChoiceQR does not document a webhook signature/secret, so this only parses the payload — it does not authenticate it.

## [0.1.0] - 2026-08-28

### Added

- `ChoiceQR::Client` — entry point; holds a static long-lived bearer token (no refresh needed, per the API's ~5 year token lifetime) and exposes accessors for every resource.
- `ChoiceQR::Client.exchange_token` — exchanges an OAuth authorization code for a long-lived access token.
- Resource wrapper classes for the full documented API surface: `Place`, `SectionInfo`, `Sections`, `Categories`, `Dishes`, `DishOptions`, `DishLabels`, `Pack`, `Cutlery`, `FullMenu` (bulk import, availability sync, chain availability sync, marketplace data sync), `Areas`, `LocationPoints`, `Orders`, `Bookings`, `Feedbacks`.
- `ChoiceQR::Resource` — generic response object with dot notation, hash access (`[]`), and `to_h`; recursively wraps nested hashes/arrays at every depth for consistent dot access on ChoiceQR's deeply nested schemas.
- `ChoiceQR::KeyTransformer` — bidirectional conversion between the API's camelCase keys and Ruby snake_case symbols, including the `posID`/`sectionPosID`/`categoryPosID` acronym special case and leading-underscore (`_id`) preservation for payloads that reference an existing entity.
- Full error hierarchy under `ChoiceQR::Error` covering 400, 401, 403, 404, 429, 5xx, and network-level errors, carrying the API's own `error_name` classification where present.
- Faraday retry middleware for 429/5xx responses, and an `x-idempotence-key` header sent on every request, per the API guidelines.

[Unreleased]: https://github.com/stockbird-app/choiceqr/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/stockbird-app/choiceqr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/stockbird-app/choiceqr/releases/tag/v0.1.0
