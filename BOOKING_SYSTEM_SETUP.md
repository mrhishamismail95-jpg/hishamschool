# Hisham Academy – Booking system integration

## What changed
- Added a student/teacher booking workspace at `/bookings`.
- Added teacher publishing of private (one seat) and group sessions.
- Added student booking for self or multiple existing student records.
- Added payment proof/reference capture and teacher approval/rejection.
- Added teacher booking attendance marking API support.
- Added student and teacher navigation entry points.

## Database migration
Apply `db/migrations/20261124_booking_system.sql`, then `db/migrations/20261124_booking_hardening.sql`, to the same Neon database used by the app before deploying the code.

## API routes
- `GET/POST /api/academy/bookable-sessions`
- `GET/POST/PATCH /api/academy/bookings`

## Important rollout requirements
1. The login API now issues a signed HttpOnly session cookie for students and teachers. Set a strong `ACADEMY_SESSION_SECRET` in the deployment environment before testing these APIs. Existing open app routes elsewhere still need a broader authentication audit.
2. Multi-student booking accepts existing student codes (for example `ST-0001`) and resolves them to existing student records; the booking student is automatically included. No duplicate student profile is created.
3. Receipt images/PDFs are uploaded through the project's existing upload endpoint (4 MB client-side limit), and the returned URL is attached to the payment record.
4. The archive did not include the live Neon schema or migrations. Verify the existing `students.id` and `teachers.id` types are compatible with BIGINT before applying the migration. No production database was changed by this integration.
5. Payment approval/rejection, booking status, history, and rejected-seat release are performed in one SQL statement.

## Seat and booking rules
- Private sessions must have exactly one seat.
- Group sessions can have multiple seats.
- Capacity is reserved atomically during booking creation.
- Unpaid holds without a submitted proof/reference expire after 30 minutes and release their seats on the next booking/session request. Once the student submits proof/reference, the booking moves to teacher review and the seat remains reserved until the teacher approves or rejects it.
- Teacher schedule overlaps are rejected when a session is published; publication is serialized per teacher to prevent simultaneous overlapping inserts.
- A unique `(session_id, student_id)` constraint prevents a student being added twice to the same session.
- Rejected payments release the reserved seats.

## Validation performed in this workspace
- JavaScript syntax checks passed for the added API/session helpers.
- JSX transpilation syntax checks passed for the booking page and the edited student/teacher dashboards.
- A full application build, database migration execution, and end-to-end booking/payment test were not run because this archive has no installed web dependencies or live Neon database credentials.
- Booking attendance is currently stored on `booking_students.attendance_status`; merging it into the legacy attendance reporting table should be done after verifying that table's live schema.
