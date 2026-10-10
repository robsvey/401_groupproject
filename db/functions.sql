-- BYU Trip Share: vertical slice ("Request a Seat")
-- Run AFTER schema.sql and seed.sql (Supabase: SQL Editor -> paste -> Run).
--
-- Security approach: Row Level Security is turned ON for every table with no
-- public policies, so the browser can't read or write tables directly (that
-- would expose phone numbers, birthdays, etc.). Instead, the browser calls these
-- three functions, which return only the fields the page needs.

-- 1. Lock every table
ALTER TABLE users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE id_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE destinations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE trips            ENABLE ROW LEVEL SECURITY;
ALTER TABLE seat_requests    ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages    ENABLE ROW LEVEL SECURITY;

-- 2. Sample riders for the "Signed in as" picker (stands in for real login in this prototype)
CREATE OR REPLACE FUNCTION get_demo_users()
RETURNS TABLE (user_id INT, first_name VARCHAR, last_name VARCHAR, username VARCHAR)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT u.user_id, u.first_name, u.last_name, u.username
    FROM users u
    ORDER BY u.first_name;
$$;

-- 3. Upcoming trips, plus the chosen rider's request status for each one
CREATE OR REPLACE FUNCTION get_trip_listings(p_rider_id INT)
RETURNS TABLE (
    trip_id            INT,
    destination_name   VARCHAR,
    category           VARCHAR,
    photo_url          TEXT,
    driver_id          INT,
    driver_first_name  VARCHAR,
    departure_location VARCHAR,
    departure_time     TIMESTAMPTZ,
    return_time        TIMESTAMPTZ,
    total_seats        INT,
    seats_available    INT,
    price_per_seat     NUMERIC,
    trip_notes         TEXT,
    trip_status        VARCHAR,
    my_request_status  VARCHAR      -- NULL if this rider hasn't requested the trip
)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
    SELECT t.trip_id, d.destination_name, d.category, d.photo_url,
           t.driver_id, u.first_name,
           t.departure_location, t.departure_time, t.return_time,
           t.total_seats, t.seats_available, t.price_per_seat, t.trip_notes, t.trip_status,
           sr.request_status
    FROM trips t
    JOIN destinations d ON d.destination_id = t.destination_id
    JOIN users u        ON u.user_id = t.driver_id
    LEFT JOIN seat_requests sr ON sr.trip_id = t.trip_id AND sr.rider_id = p_rider_id
    WHERE t.trip_status <> 'cancelled'
    ORDER BY t.departure_time;
$$;

-- 4. THE VERTICAL SLICE: save a seat request and return the saved row
CREATE OR REPLACE FUNCTION request_seat(p_trip_id INT, p_rider_id INT, p_message VARCHAR DEFAULT NULL)
RETURNS TABLE (request_id INT, trip_id INT, rider_id INT, request_status VARCHAR, requested_at TIMESTAMPTZ)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
    v_trip trips%ROWTYPE;
BEGIN
    SELECT * INTO v_trip FROM trips t WHERE t.trip_id = p_trip_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'This trip no longer exists.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM users u WHERE u.user_id = p_rider_id) THEN
        RAISE EXCEPTION 'Rider not found. Please sign in again.';
    END IF;
    IF v_trip.driver_id = p_rider_id THEN
        RAISE EXCEPTION 'You are the driver for this trip.';
    END IF;
    IF v_trip.trip_status <> 'open' OR v_trip.seats_available < 1 THEN
        RAISE EXCEPTION 'This trip is full or no longer accepting requests.';
    END IF;
    IF EXISTS (SELECT 1 FROM seat_requests s WHERE s.trip_id = p_trip_id AND s.rider_id = p_rider_id) THEN
        RAISE EXCEPTION 'You have already requested a seat on this trip.';
    END IF;

    RETURN QUERY
    INSERT INTO seat_requests AS s (trip_id, rider_id, seats_requested, request_message, request_status)
    VALUES (p_trip_id, p_rider_id, 1, p_message, 'pending')
    RETURNING s.request_id, s.trip_id, s.rider_id, s.request_status, s.requested_at;
END;
$$;

-- 5. Only these functions are callable from the browser
REVOKE ALL ON FUNCTION get_demo_users()                    FROM PUBLIC;
REVOKE ALL ON FUNCTION get_trip_listings(INT)              FROM PUBLIC;
REVOKE ALL ON FUNCTION request_seat(INT, INT, VARCHAR)     FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_demo_users()                TO anon, authenticated;
GRANT EXECUTE ON FUNCTION get_trip_listings(INT)          TO anon, authenticated;
GRANT EXECUTE ON FUNCTION request_seat(INT, INT, VARCHAR) TO anon, authenticated;
