# Scope: Environment & Base URL Configuration (Milestone 1)

## Architecture
- `ApiService` in `lib/core/network/api_service.dart` will consume environment variables using `String.fromEnvironment` at compile time.
- JSON configuration files will be created in `env/` directory in the mobile app root (e.g. `development.json`, `staging.json`, `production.json`) for use with `--dart-define-from-file`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Create Env JSON configs | Create `env/development.json`, `env/staging.json`, `env/production.json` | None | DONE |
| 2 | Refactor ApiService | Update `api_service.dart` to read configuration at compile time | 1 | DONE |

## Interface Contracts
- `const String.fromEnvironment('API_BASE_URL')` for fetching base URL.
- `const String.fromEnvironment('APP_MODE')` for fetching environment mode.
