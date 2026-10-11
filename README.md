# Camera Cloud PWA

Flutter web camera with photo capture and chunked video upload to a private cloud, followed by laptop synchronization.

## Current scope
- Flutter web interface and browser camera bridge.
- Photo capture uploads immediately.
- MediaRecorder emits chunks while recording; each chunk uploads independently using signed URLs.
- No intentional saving to the iPhone Photos library.
- Laptop sync service scaffold; production credentials and infrastructure are still required.

**Limitations:** Safari can pause or stop recording when backgrounded or locked. Browser RAM and caches are not guaranteed to remain empty. A video chunk is not necessarily independently playable: finalization/concatenation must preserve container format.

## Run
Install Flutter SDK, then from repository root:

```sh
flutter create . --platforms web
flutter pub get
flutter run -d chrome
```

Run on HTTPS or localhost. Camera access requires permission.

## Cloud contract
Set `API_BASE_URL` with `--dart-define`. API endpoints require authenticated user identity in production:
- POST /api/uploads/start -> {sessionId}
- POST /api/uploads/{sessionId}/part -> {url, method, headers, partId}
- POST /api/uploads/{sessionId}/finish -> final media object
- POST /api/photos/sign -> {url, method, headers}

Signed URLs must be scoped to one authenticated user, one object, limited size and lifetime. Never ship Supabase service-role keys to browser.

## Laptop sync
A laptop agent should poll authorized completed media records, download through short-lived URLs, verify checksums, and record sync acknowledgments. Not implemented in this initial commit.

## Privacy
Repository is currently public. No credentials should be committed.
