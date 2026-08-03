# shell

The authenticated application chrome: sidebar, top bar, and the routed content area.

- `nav-config.ts` — **the navigation.** Add your product's entries here; capability-gate them with
  `requiredCapability`, remembering that hiding a link is UX, not security.
- `app-layout.ts` — the layout component the `authGuard`-protected route group renders into. It
  also owns the route -> page-title mapping (`metaForPath`), the redirect on session expiry, and
  the "What's new" wiring below.
- `sidebar.ts` / `top-bar.ts` — presentation only.

Public routes (login, auth callback, signing out, 404) deliberately render OUTSIDE this shell.

## The "What's new" check lives here on purpose

`app-layout.ts` runs an `effect` on every router `NavigationEnd` that asks
`FeatureAnnouncementsApiService.unack()` whether anything is pending for the current path, and
renders `<app-whats-new-modal>` when something is. It is at the shell and never inside a page so
that every route is covered with no per-page wiring, and so one announcement can be scoped to
several unrelated pages.

Two things in that effect are load-bearing and easy to "tidy" into bugs:

- The pending signal is **only ever set to a non-empty list, never cleared on success** — a fast
  double-navigation racing the response would otherwise blank a modal the user is still reading.
  It is cleared only in `onWhatsNewClosed`, on a deliberate dismiss.
- `onWhatsNewClosed` **clears locally first, then POSTs**, so a failed acknowledgement still closes
  the modal. Both error handlers are silent by design.

Full detail, including how announcements are authored and previewed:
[`docs/whats-new.md`](../../docs/whats-new.md).
