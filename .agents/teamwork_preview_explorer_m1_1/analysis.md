# Analysis and Implementation Plan - Environment & Widget Test Fixes (Milestone 1)

This report details the findings and implementation plan for Milestone 1, focusing on configuring environment-specific variables and fixing the failing widget smoke test in the mobile application.

## Core Findings Summary
- Loaded compile-time environment configurations (`API_BASE_URL` and `APP_MODE`) using `String.fromEnvironment` in `ApiService` with safe runtime defaults that preserve emulator/loopback logic.
- Resolved the failing `widget_test.dart` by wrapping `EazzioBooksApp` inside a `ProviderScope` and refactoring assertions to target the actual application's `LoginScreen` branding rather than a non-existent counter widget.

---

## 1. Observation

### Current Implementation & Issue Points
- **API Base URL configuration (`eazzio_books_mobile/lib/core/network/api_service.dart:28-30`)**:
  ```dart
  dio.options.baseUrl = kIsWeb
      ? 'http://localhost:5001/api'
      : (Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api');
  ```
  This hardcodes the host addresses. There is no mechanism to define configuration files for development, staging, or production environments.
  
- **Failing Widget Test (`eazzio_books_mobile/test/widget_test.dart:14-29`)**:
  ```dart
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EazzioBooksApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    // ...
  ```
  Running `flutter test` throws:
  - `ProviderScope` error (because `EazzioBooksApp` uses `ConsumerWidget` and watches `routerProvider`, which relies on `ProviderContainer`/`ProviderScope`).
  - Expectation failures (because the counter widget code does not exist in the project).

---

## 2. Logic Chain

1. **Environment Separation**: 
   - Flutter supports building environment-specific bundles via the `--dart-define-from-file` parameter, loading variables from flat JSON configuration files.
   - We will define three configuration files in `env/` to supply `API_BASE_URL` and `APP_MODE`.
   
2. **Robust Fallback in `ApiService`**:
   - `String.fromEnvironment` provides static constant values at compile time.
   - For `API_BASE_URL`, if not provided or left blank, the app must fallback to the dynamic address logic based on the platform (Web, Android emulator `10.0.2.2:5001`, or iOS/Desktop `localhost:5001`).
   - For `APP_MODE`, it must fallback to `'development'`.
   - The logging interceptor should trigger when `kDebugMode` is true OR when `APP_MODE` is either `'development'` or `'staging'`.

3. **Widget Test Fix**:
   - Wrap the root pumped widget with a `ProviderScope`.
   - Update the test description and expectations to reflect the actual initial landing screen: `LoginScreen` which contains branding text `Eazzio Books` and submit button text `Sign In`.

---

## 3. Caveats
- **Local Address fallbacks**: The dynamic fallback assumes that local backend servers are listening on port `5001` with path `/api`.
- **JSON Formatting**: When run in CI or run commands, files must be supplied via `--dart-define-from-file=env/<env>.json`.

---

## 4. Conclusion & Plan

We have formulated a clean implementation plan that does not introduce breaking changes to local development workflows.

### A. Environment Configuration JSON Files

#### `env/development.json`
```json
{
  "API_BASE_URL": "",
  "APP_MODE": "development"
}
```

#### `env/staging.json`
```json
{
  "API_BASE_URL": "https://staging-api.eazziobooks.com/api",
  "APP_MODE": "staging"
}
```

#### `env/production.json`
```json
{
  "API_BASE_URL": "https://api.eazziobooks.com/api",
  "APP_MODE": "production"
}
```

### B. Code Changes

#### 1. Refactoring `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile/lib/core/network/api_service.dart`

```dart
// proposed replacement snippet (Lines 11-52)
class ApiService {
  // Compile-time environment variables
  static const String appMode = String.fromEnvironment('APP_MODE', defaultValue: 'development');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  late final Dio dio;
  late final PersistCookieJar cookieJar;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    dio = Dio();

    // 1. Setup persistent cookie store
    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/cookies';
    cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    dio.interceptors.add(CookieManager(cookieJar));

    // 2. Base URL mapping (handles local Android emulator loopback vs generic desktop/iOS)
    final String defaultBaseUrl = kIsWeb
        ? 'http://localhost:5001/api'
        : (Platform.isAndroid ? 'http://10.0.2.2:5001/api' : 'http://localhost:5001/api');

    dio.options.baseUrl = apiBaseUrl.isNotEmpty ? apiBaseUrl : defaultBaseUrl;

    dio.options.connectTimeout = const Duration(seconds: 10);
    dio.options.receiveTimeout = const Duration(seconds: 10);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Logging interceptor for debugging network logs
    final activeAppMode = appMode.isNotEmpty ? appMode : 'development';
    if (kDebugMode || activeAppMode == 'development' || activeAppMode == 'staging') {
      dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ));
    }

    _isInitialized = true;
  }
```

#### 2. Fixing `/home/rahul-kumar/Desktop/Eazzio-Books/eazzio_books_mobile/test/widget_test.dart`

```dart
// Entire proposed content for test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eazzio_books_mobile/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: EazzioBooksApp(),
      ),
    );

    // Allow any initial animations or navigation to complete
    await tester.pumpAndSettle();

    // Verify that the login screen is displayed by finding branding text
    expect(find.text('Eazzio Books'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
```

---

## 5. Verification Method

To verify these changes:
1. Run `flutter test` directly. It should pass perfectly.
2. Compile and run with specific environment targets:
   - For Development: `flutter run --dart-define-from-file=env/development.json`
   - For Staging: `flutter run --dart-define-from-file=env/staging.json`
   - For Production: `flutter run --dart-define-from-file=env/production.json`
3. We have verified the proposed widget test fix locally against our proposed service module using a test wrapper at `.agents/teamwork_preview_explorer_m1_1/test_widget_test.dart`, and it yielded:
   ```
   All tests passed!
   ```
