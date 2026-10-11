# Android biometric sign-in

On a supported Android phone with an enrolled strong biometric, choose
**Enable fingerprint sign-in on this phone** when signing in with the account
password. Setup uses Android's system biometric prompt after the backend accepts
the password. Temporary passwords must be changed before setup can complete.
The option is unavailable on web, Windows and unsupported or unenrolled phones.

Once enabled, the system fingerprint prompt opens automatically when the login
screen becomes visible in the foreground. It waits for navigation transitions
and any covering update or other dialog to finish. Setup is hidden for enrolled
accounts, and the login page does not display the saved email or removal controls.
Cancellation and lockout leave password sign-in available without repeated
automatic prompts; **Sign in with fingerprint** allows a deliberate retry.
This is a faster account sign-in method, not
an application lock: an existing valid session continues to use the configured
session expiry and inactivity rules.

The AndroidX Biometric prompt authorizes a per-operation Android Keystore
AES/GCM key. Only encrypted account credentials and their IV are persisted;
the email address is also retained for identifying the saved account in profile
settings. No plaintext password or biometric image is stored. The key is
invalidated when biometric enrollment changes or the secure lock is removed.
Biometric storage is excluded from cloud backup and device transfer.
Anyone whose eligible biometric is enrolled on that phone can authorize access;
the opt-in text explains this before setup.

Every successful biometric unlock submits a fresh request to `/account/login`.
It does not bypass approval, disabled-account checks, required password changes
or role selection. A 401/403 rejection clears the saved sign-in; network/server
failures retain it for retry. Password changes elsewhere require password
sign-in and new setup. No API schema or Firebase configuration changes are needed.

Only one account is remembered per phone. Opting in for a different account
replaces the previous saved credential. Manage or remove it in
**My profile → Fingerprint sign-in → Remove from this phone**. Ordinary logout
ends the API session while preserving this explicitly opted-in sign-in method.
The former technician-only “Biometric unlock” preference was a local display
toggle and has been replaced with the working shared control.

Automated tests cover platform gating, cancellation, duplicate submissions,
backend rejection/outages, opt-in, role selection and required password changes.
Physical-device testing on an enrolled phone should also verify:

1. Normal sign-in, setup approval, logout, fingerprint sign-in and password fallback.
2. Cancellation, nonmatching fingerprints and temporary lockout.
3. Removing/re-enrolling fingerprints, and removing the phone's secure lock.
4. Password change or account suspension on the server.
5. Removing saved sign-in, replacing the saved account, and reinstalling/restoring.

Implementation follows Android's [biometric authentication and cryptography
guidance](https://developer.android.com/identity/sign-in/biometric-auth).
