# Simulator MCP page tour

Run app with driver enabled (required for Cursor dart MCP `flutter_driver_command`):

```bash
cd mobile
flutter run -t lib/main_driver.dart -d "iPhone 17 Pro" \
  --dart-define=API_URL=http://localhost:3001/v1
```

E2E API user (from `e2e-register-iban-link.sh`):

- Email: `e2e-1779735070@payspin.test`
- Password: `E2eTestPass123!`
- Link id: `b00c4425-0e56-479b-9a02-5436668dfa1e`

Integration tests (all routes):

```bash
flutter test integration_test/all_pages_e2e_test.dart -d "iPhone 17 Pro" \
  --dart-define=API_URL=http://localhost:3001/v1
```
