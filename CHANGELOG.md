# Changelog

## Cleanup — remove dead v1.6 UI (post v1.7)

- Removed voucher activate/validate API stubs and related error mappings.
- Removed Email Link Code Settings row and stub (use Settings → Link Code instead).
- Removed IPA cache reinstall stub and intermediate Size/In Update cache screen; Install History now opens the history list directly (`get_installation_history`).
- Removed unused `appsync` / `forceDisablePRO` preference leftovers.
- Remapped Advanced Options “revocation” toggle to v1.7 `use_revoked_certs`.
- Grouped Settings (Libraries & Status, Notifications) and improved Downloads empty-state copy.
- Kept working search types `ios` / `cydia` / `books` (still present in API v1.7 `contentType`).

## v1.7 API Modernization (GetsugaTensh0 fork)

Updated by [Dustin Seehaver](https://github.com/GetsugaTensh0) to work with the latest appdb.to API (v1.7).

### API migration

- Converted all API calls from GET to POST with form-encoded parameters and trailing-slash endpoints, matching the v1.7 contract.
- Added UOID (Universal Object Identifier) support for content lookups and installs.
- Updated subscription/notification actions for v1.7 response format.
- Fixed multipart uploads to include required `lt`/`lang`/`brand` form fields.

### Bug fixes

- Fixed downloads stuck in "queued" status after successful install.
- Fixed crashes, race conditions, and excessive polling in the download manager.
- Fixed 404 errors on deprecated endpoints (migrated to current v1.7 paths).
- Fixed response parsing for changed JSON structures in v1.7.
- Fixed widget parameters for the home-screen widget.
- Fixed enhancement deletion (use `id` instead of `name`), IPA deletion, and dylib ID tracking.
- Fixed hardcoded legacy content IDs; replaced with v1.7 equivalents.
- Fixed MyAppStore app installs (fresh tickets, universal ticket flow).
- Removed dead IPA cache stubs left over from v1.6.

### Other improvements

- Added localization strings for new user-facing text.
- Added unsigned IPA build via GitHub Actions (CI on every push to master).
