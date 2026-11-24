-- Hisham Academy: individual and group session booking
-- Idempotent migration. Review ID column types against the live Neon schema before production rollout.
CREATE TABLE IF NOT EXISTS bookable_sessions (
  id BIGSERIAL PRIMARY KEY,
  teacher_id BIGINT NOT NULL,
  session_type TEXT NOT NULL CHECK (session_type IN ('private','group')),
  subject TEXT NOT NULL,
  grade TEXT,
  topic TEXT NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  price_per_seat NUMERIC(12,2) NOT NULL CHECK (price_per_seat >= 0),
  capacity INTEGER NOT NULL CHECK (capacity >= 1),
  reserved_seats INTEGER NOT NULL DEFAULT 0 CHECK (reserved_seats >= 0),
  delivery_mode TEXT NOT NULL DEFAULT 'online' CHECK (delivery_mode IN ('online','in_person')),
  meeting_url TEXT,
  location TEXT,
  status TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('draft','published','full','completed','cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ends_at > starts_at),
  CHECK ((session_type <> 'private' OR capacity = 1) AND (session_type <> 'group' OR capacity >= 2))
);
CREATE INDEX IF NOT EXISTS idx_bookable_sessions_public ON bookable_sessions(status, starts_at);
CREATE INDEX IF NOT EXISTS idx_bookable_sessions_teacher ON bookable_sessions(teacher_id, starts_at);

CREATE TABLE IF NOT EXISTS session_bookings (
  id BIGSERIAL PRIMARY KEY,
  session_id BIGINT NOT NULL,
  booked_by_student_id BIGINT NOT NULL,
  seat_count INTEGER NOT NULL CHECK (seat_count >= 1),
  total_amount NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0),
  status TEXT NOT NULL DEFAULT 'pending_payment' CHECK (status IN ('pending_payment','payment_review','confirmed','cancelled','rejected','refunded','completed')),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_session_bookings_student ON session_bookings(booked_by_student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_session_bookings_session ON session_bookings(session_id, status);

CREATE TABLE IF NOT EXISTS booking_students (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT NOT NULL,
  session_id BIGINT NOT NULL,
  student_id BIGINT NOT NULL,
  seat_price NUMERIC(12,2) NOT NULL,
  attendance_status TEXT NOT NULL DEFAULT 'not_marked' CHECK (attendance_status IN ('not_marked','present','absent','late')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (session_id, student_id)
);
CREATE INDEX IF NOT EXISTS idx_booking_students_student ON booking_students(student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_booking_students_booking ON booking_students(booking_id);

CREATE TABLE IF NOT EXISTS booking_payments (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  payment_method TEXT NOT NULL DEFAULT 'bank_transfer',
  reference TEXT,
  proof_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','under_review','approved','rejected','refunded')),
  reviewed_by_teacher_id BIGINT,
  reviewed_at TIMESTAMPTZ,
  review_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_booking_payments_booking ON booking_payments(booking_id, created_at DESC);

CREATE TABLE IF NOT EXISTS booking_status_history (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT NOT NULL,
  old_status TEXT,
  new_status TEXT NOT NULL,
  actor_role TEXT NOT NULL,
  actor_id BIGINT,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
