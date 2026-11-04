
# AGENTS.md — Tawseel Stops

## Project constraints
- Keep the package name `dsc26_flt_w04`; never rename it.
- Use the Flutter and Dart versions allowed by `pubspec.yaml`.
- Read the existing implementation and README before changing code.
- Preserve the public API and constructor of `TawseelStopsApp`.
- Do not modify the provided domain models or `LocalStore` implementations.
- Keep the required widget keys used by the tests.

## Outbox rules
- Store the queue under `tawseel.outbox.v1`.
- Validate every outcome before changing or persisting the queue.
- Require a non-empty parcel ID and a UTC `recordedAt`.
- Delivered outcomes need non-negative COD and no failure reason.
- Failed outcomes need a failure reason and zero COD.
- Await persistence before `record()` completes.
- Generate a new ID only when appending a new entry.
- Replace a matching pending entry only when `attempts == 0`.
- Append corrections when the existing entry has already been attempted.
- Send pending entries oldest first using `POST /v1/outcomes`.
- Include JSON content type and the entry ID as `Idempotency-Key`.
- Treat 200, 201, and 409 as successful responses.
- Mark 400 and 422 as rejected, then continue syncing.
- Stop on 401 without removing the pending entry.
- Stop on transient failures; never skip the failed entry.
- Persist queue changes made during synchronization.
- Ensure concurrent `sync()` calls share the same in-progress future.
- Implement exponential retry delays starting at 5 seconds, capped at 300 seconds.

## UI and accessibility rules
- Use a width-based breakpoint: compact below 600px, expanded at 600px and above.
- Preserve `layout-compact`, `layout-expanded`, `stop-detail`, and other required keys.
- Keep every tappable target at least 48x48 and provide an accessible label.
- Do not use fixed heights around text; support 200% text scaling.
- Use directional layout properties to support both LTR and RTL.
- Keep the sync banner's required single semantics label and live-region behavior.

## Verification
- Run `dart format` on changed Dart files.
- Run `flutter analyze` and `flutter test` before submitting.
- Fix errors without weakening or removing tests.
