# Local notifications across roles

`MessageNotificationHost` is mounted once in the application shell for all roles.
It polls authenticated chat and workflow inboxes every five seconds (requests do
not overlap). Both feeds keep their own baseline and failures do not erase the
last successful inbox or block the other feed. First-load historical items stay
in the center without replaying device alerts.

- Android uses native `team_messages`, `farm_updates` and silent update channels.
  Android 13+ requires notification permission. Tap opens the conversation or
  shared notification center; read items are dismissed on refresh.
- Windows uses `local_notifier` native toasts. The running app keeps polling
  while minimized, and clicking a toast restores the window before navigation.
  Linux/macOS use the plugin's desktop adapter but have not been device-tested.
- Web uses the browser Notifications API. Use **Enable device notifications**
  in the bell's notification center to request permission through a user gesture.
  HTTPS (or localhost) and browser support are required. An unsupported browser,
  including mobile browsers that require service-worker notifications, falls
  back to the in-app banner and inbox. Open tabs may be throttled by the browser.

OS delivery failure or denied permission falls back to an in-app banner. System
previews omit message/farm/financial details. Caretaker chat, task, anomaly and
sound preferences affect presentation; muted items remain in the center.
Signing out clears local alerts, the inbox and deduplication state. Late results
and taps from a previous session cannot open its content.

## Explicit local-only limit

No Firebase, background polling service, push registration or Web Push is used.
New remote events are fetched while the client is running. Android suspension,
closing the Windows app, or closing the web page stops new delivery. Existing
unread events are available in the inbox on the next launch. This is not
closed-app push, and Android local notifications alone cannot wake the app when
another device creates a backend event.

The backend coverage matrix is `farm_appwrite_api/docs/notification-coverage.md`.
Deploy backend and frontend together; workflow inbox reads now require the
current user's Bearer token. There is no new database schema migration.

Release checklist: test permission granted/denied, tap while minimized,
read/dismiss synchronization, muted categories, app resume, logout/account
switch, and browser support on real target devices. Compilation and mocked
transport tests do not substitute for an OS notification-permission check.

## Reading and opening notifications

The bell opens a 500px maximum desktop dialog and an Android/mobile bottom
sheet using the shared Sales modal style. Header and footer remain fixed while
the list or full message scrolls. Every card offers Read message; the detail
view shows selectable, untruncated stored text and its full local timestamp.
Known destinations also offer a role-specific Open/View action. Informational,
unknown, unsupported-role and legacy ambiguous financial notifications stay in
the detail view. Backend-supplied URLs and free-form message text never select
a route. An account change closes the dialog and invalidates pending navigation.

New fund-request, withdrawal, account-review, sensor-alert and inventory-alert categories distinguish
those destinations without a schema migration. Caretaker task actions open the
live calendar with assigned tasks and batch schedules. Accountant fund and withdrawal
notifications open the database-backed approval queue. Both endpoints require an
authenticated session; reviews persist the decision and audit the reviewer without
initiating a payment. Deploy the matching API update before using these screens.
