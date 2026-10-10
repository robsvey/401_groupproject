-- BYU Trip Share: database schema
-- Works in PostgreSQL and Supabase (paste into the Supabase SQL Editor and click Run).

DROP TABLE IF EXISTS chat_messages, seat_requests, trips, destinations, id_verifications, users CASCADE;

-- One row per BYU student account (drivers and riders are both users)
CREATE TABLE users (
    user_id               SERIAL PRIMARY KEY,
    username              VARCHAR(30)  NOT NULL UNIQUE,
    first_name            VARCHAR(50)  NOT NULL,
    last_name             VARCHAR(50)  NOT NULL,
    byu_email             VARCHAR(100) NOT NULL UNIQUE CHECK (byu_email LIKE '%@byu.edu'),
    phone_number          VARCHAR(20)  NOT NULL,
    date_of_birth         DATE         NOT NULL,
    password_hash         VARCHAR(255) NOT NULL,   -- never store plain-text passwords
    profile_photo_url     TEXT,
    hometown_city         VARCHAR(80),
    hometown_state        VARCHAR(40),
    location_access_granted BOOLEAN    NOT NULL DEFAULT FALSE,
    created_at            TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- One-to-one with users: the ID a user uploads at sign-up to be verified
CREATE TABLE id_verifications (
    verification_id   SERIAL PRIMARY KEY,
    user_id           INT NOT NULL UNIQUE REFERENCES users(user_id) ON DELETE CASCADE,
    document_type     VARCHAR(20) NOT NULL CHECK (document_type IN ('byu_student_id', 'drivers_license')),
    document_image_url TEXT NOT NULL,
    status            VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'verified', 'rejected')),
    submitted_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at       TIMESTAMPTZ
);

-- Destination cards on the Home / Search screen
CREATE TABLE destinations (
    destination_id        SERIAL PRIMARY KEY,
    destination_name      VARCHAR(80)  NOT NULL,
    city                  VARCHAR(80)  NOT NULL,
    state                 VARCHAR(40)  NOT NULL,
    category              VARCHAR(30)  NOT NULL,          -- e.g. 'Ski trip', 'National park'
    photo_url             TEXT,
    est_drive_minutes     INT          NOT NULL CHECK (est_drive_minutes > 0),
    est_price_per_rider   NUMERIC(6,2) NOT NULL CHECK (est_price_per_rider >= 0)
);

-- A trip a driver posts to a destination
CREATE TABLE trips (
    trip_id             SERIAL PRIMARY KEY,
    driver_id           INT NOT NULL REFERENCES users(user_id),
    destination_id      INT NOT NULL REFERENCES destinations(destination_id),
    departure_location  VARCHAR(120) NOT NULL,
    departure_time      TIMESTAMPTZ  NOT NULL,
    return_time         TIMESTAMPTZ,
    total_seats         INT          NOT NULL CHECK (total_seats BETWEEN 1 AND 8),
    seats_available     INT          NOT NULL,
    price_per_seat      NUMERIC(6,2) NOT NULL CHECK (price_per_seat >= 0),
    trip_notes          TEXT,
    trip_status         VARCHAR(10)  NOT NULL DEFAULT 'open' CHECK (trip_status IN ('open', 'full', 'cancelled', 'completed')),
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    CHECK (seats_available BETWEEN 0 AND total_seats)
);

-- Bridge table: resolves the many-to-many between riders (users) and trips
CREATE TABLE seat_requests (
    request_id       SERIAL PRIMARY KEY,
    trip_id          INT NOT NULL REFERENCES trips(trip_id) ON DELETE CASCADE,
    rider_id         INT NOT NULL REFERENCES users(user_id),
    seats_requested  INT NOT NULL DEFAULT 1 CHECK (seats_requested >= 1),
    request_message  VARCHAR(300),
    request_status   VARCHAR(10) NOT NULL DEFAULT 'pending' CHECK (request_status IN ('pending', 'accepted', 'denied', 'cancelled')),
    requested_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    responded_at     TIMESTAMPTZ,
    UNIQUE (trip_id, rider_id)            -- a rider can only request a given trip once
);

-- Group chat: every message belongs to one trip's chat
CREATE TABLE chat_messages (
    message_id    SERIAL PRIMARY KEY,
    trip_id       INT NOT NULL REFERENCES trips(trip_id) ON DELETE CASCADE,
    sender_id     INT NOT NULL REFERENCES users(user_id),
    message_body  VARCHAR(1000) NOT NULL,   -- 1,000-character limit from the behavioral requirements
    sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
