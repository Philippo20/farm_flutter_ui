# Message notifications

The shared application shell checks the authenticated `/messages/notifications`
inbox every five seconds while the app is active. The backend derives alerts
from saved incoming messages, so send retries do not create duplicate alerts and
message read receipts stay synchronized across devices.

The notification center shows message alerts with a shortcut to the sender's
conversation. Desktop and mobile web show an in-app banner for new arrivals.
Android uses the `team_messages` system notification channel, requests Android
13+ notification permission, groups arrivals by sender, and opens the matching
conversation on tap. Message content is omitted from the system notification.
Old unread messages appear in the center without replaying system alerts on
each launch. Reading a conversation clears its system notification on the next
refresh. Signing out clears notification state and stops polling.

## Background delivery still required

The current Android implementation receives updates while the app is active.
It does **not** receive new messages while Android has suspended or terminated
the app. Completing that feature requires the app's Firebase project details,
FCM client integration and authenticated device registration, and a backend push
sender (direct FCM or an Appwrite FCM provider). Do not replace this with a
background polling loop or advertise it as background push.

Reference: https://firebase.google.com/docs/cloud-messaging/android/get-started

Both the backend and frontend notification changes need deployment together.
