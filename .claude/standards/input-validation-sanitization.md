# Standard: Input Validation & Sanitization (frontend)

Client-side validation is a UX convenience, never a security control. The API validates and
authorizes every request independently, regardless of what the client already checked — see
[`owasp-security.md`](owasp-security.md). This document covers what the frontend is
responsible for.

## Form validation

- **Typed reactive forms** (`FormBuilder.nonNullable`, `FormGroup<T>`) carry their own
  validators (`Validators.required`, `maxLength`, custom validators) so obviously-invalid input
  never reaches a submit call — see [`angular.md`](angular.md#forms).
- Validation messages come from a shared error-message map, not inline strings duplicated per
  field.
- **A field only shows its error after it is touched or dirty**
  (`control.invalid && (control.touched || control.dirty)`), so a fresh form does not open with
  a wall of red text.
- **Server-side validation errors are the ones that count.** When the API rejects a submission
  with `400`/`422` and `errors[]` (see [`api-response-format.md`](api-response-format.md)), map
  those messages back onto the corresponding controls. A form that only trusts its own
  client-side rules will happily submit something the server correctly rejects, and the user
  needs to see why.
- Disable submit while a request is in flight; do not rely on the user not double-clicking a
  create/update action into a duplicate.
- **Never assume client-side validation is a substitute for the server's.** It exists to give
  the user fast feedback, not to gate what the API accepts. A validation rule that only exists
  client-side is not a rule — it is a suggestion.

## Rendering user content — never bypass Angular's escaping

- **Angular escapes interpolated content by default.** `{{ value }}` in a template is always
  safe against HTML/script injection; do not "fix" a rendering quirk by switching to
  `[innerHTML]`.
- **`[innerHTML]` with any value that could contain user-supplied or API-supplied text
  requires sanitization and a reviewed, commented justification at the binding site** — state
  *why* raw HTML is needed and what sanitizes it (Angular's `DomSanitizer`, or the content is
  provably already sanitized upstream).
- **`bypassSecurityTrustHtml` / `bypassSecurityTrustUrl` / `bypassSecurityTrustResourceUrl` /
  `bypassSecurityTrustScript` / `bypassSecurityTrustStyle` are all a decision to skip Angular's
  built-in XSS protection for that value.** Each call site needs a comment saying why the
  content is trusted (e.g. "server-rendered rich text, sanitized server-side, see ADR-000X") —
  not because policy requires a comment, but because a `bypassSecurityTrust*` call with no
  stated reason is the single easiest way to reintroduce stored/reflected XSS into an Angular
  app.
- Prefer structured data + template bindings over raw HTML wherever the content can be
  expressed that way at all.

## File upload (client side)

- Validate the file's declared type and size client-side **only as UX** (fail fast, avoid an
  upload that the server will reject anyway) — never as the security control. The server
  re-validates by sniffing content, not trusting the `Content-Type` the browser sent.
- Show the user a clear rejection reason (too large, wrong type) rather than a generic upload
  failure.
- Never render an uploaded file's content as HTML/script in the same origin without the same
  sanitization scrutiny as any other user content.

## URLs from untrusted input

- **Any URL built from a query parameter, a stored value, or user input and then used for
  navigation must be validated before use.** `libs/auth/src/lib/sanitize-return-path.ts` is the
  reference pattern: it parses a candidate redirect target with the WHATWG `URL` parser (the
  same parser the actual navigation sink uses) and rejects anything that resolves off-origin,
  closing the class of open-redirect bugs that a `startsWith('/')` string check would miss
  (leading `\`, embedded tab/newline, protocol-relative `//`).
- Never pass an untrusted string directly to `window.location.assign`, `Router.navigateByUrl`,
  or a resource URL binding without the same treatment.

## Rules

- **Whitelist, don't blacklist**, in every client-side check that exists: known statuses, known
  formats, explicit maximum lengths — reject the unexpected rather than trying to filter it.
- **Never bind a server-owned field from a form the user can edit** (id, status transitions the
  user isn't permitted to make, audit fields, `rowVersion` other than the one the server gave
  you). The server owns those; the client only ever echoes back what it was given.
- A validation message must not reveal information about a resource the caller cannot see —
  that discipline is the API's job (see [`owasp-security.md`](owasp-security.md)), but the
  client must not paper over an API's generic message with a more specific guess of its own.

## Related

[`error-handling.md`](error-handling.md) · [`owasp-security.md`](owasp-security.md) ·
[`api-response-format.md`](api-response-format.md) · [`angular.md`](angular.md)
