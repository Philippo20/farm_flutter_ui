# Global inactivity sessions

Deploy the backend `/account/session` endpoint before releasing this Flutter version. No schema migration is required. The API key must support Appwrite Users get-session/create-JWT/delete-session operations. Existing expired JWTs require a fresh login.

The saved System Config `session_timeout` is minutes without user input. `session_idle_warning_minutes` is the warning period before that deadline (30 and 5 means warn after 25 idle minutes). Every signed-in role and route uses the same monitor on desktop, mobile web, and Android. Policy changes are read within a minute while foregrounded, and on resume.

Pointer, scrolling, and keyboard input count as activity. API polling does not. Last activity persists across restarts; background time counts. After the warning opens only explicit, successfully verified Continue resets activity. Logout/expiry clears navigation history and local authentication and attempts to revoke the Appwrite session. Expired/revoked tokens and inactive accounts cannot renew. Network failures preserve the warning and original deadline.

The new endpoint verifies the JWT with Appwrite before reading its session claim and issues a short-lived JWT linked to that same session. It returns only the timeout policy, not System Config secrets. This implements app-wide inactivity handling; it does not add authorization to legacy business API routes or implement the separate two-factor, concurrent-session, or password-policy settings. Inactivity is tracked by the app, not a durable server-side idle ledger.

Checks: session widget tests cover mobile/desktop warning, continuation, expiration, and offline rejection. Backend isolated handler tests cover expired/revoked authentication, inactive users, session binding, and public policy fields. Production Appwrite and physical Android behavior still require deployment verification.
