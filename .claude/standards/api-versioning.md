# Standard: API Versioning (client rule)

The frontend calls versioned API paths only. How the server implements versioning,
deprecation, or content negotiation is out of scope here — this is the client-side rule.

## Rules

- **The app calls versioned endpoints only:**
  ```
  /api/v1/items
  /api/v1/items/{id}
  ```
  No service in `libs/data-access/api-client` calls an unversioned path.
- **Types and clients are generated against a specific version's OpenAPI document.**
  `npm run generate:api` targets one version at a time; if the backend publishes `v1` and `v2`
  side by side, regenerating for `v2` is a deliberate, reviewed change — not an accidental
  drift.
- **A breaking upstream change means a coordinated version bump, not a silent adaptation.** If
  the API introduces `/api/v2/...` for a breaking change, migrating the frontend to it is its
  own tracked piece of work: regenerate types, update every call site, and verify behaviour
  end-to-end before removing the `v1` code paths.
- **Deprecation headers are surfaced, not ignored.** If a response carries `Deprecation` /
  `Sunset` headers, treat that as a signal to schedule the migration — do not wait for the
  endpoint to disappear.
- **Never hand-roll a version string into a URL.** The version segment comes from the generated
  client's base path / service configuration, in one place, so bumping it is a one-line change.

## Naming

Resource names in the paths the client calls are plural and kebab-case: `items`,
`item-categories` — matching whatever the API publishes.

## Related

[`api-response-format.md`](api-response-format.md) · [`angular.md`](angular.md)
