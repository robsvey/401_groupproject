-- BYU Trip Share: sample data (run after schema.sql)
-- password_hash values are placeholders, not real hashes.

INSERT INTO users (username, first_name, last_name, byu_email, phone_number, date_of_birth, password_hash, profile_photo_url, hometown_city, hometown_state, location_access_granted) VALUES
('jsmith22',   'Jake',    'Smith',    'jsmith22@byu.edu',   '801-555-0101', '2005-03-14', 'hash_placeholder_1', 'https://picsum.photos/seed/jake/200',    'Boise',      'ID', TRUE),
('emilyr',     'Emily',   'Rasmussen','emilyr@byu.edu',     '801-555-0102', '2004-11-02', 'hash_placeholder_2', 'https://picsum.photos/seed/emily/200',   'Mesa',       'AZ', TRUE),
('tannerb',    'Tanner',  'Brooks',   'tannerb@byu.edu',    '801-555-0103', '2003-07-21', 'hash_placeholder_3', 'https://picsum.photos/seed/tanner/200',  'Sacramento', 'CA', FALSE),
('mia_lopez',  'Mia',     'Lopez',    'mlopez7@byu.edu',    '801-555-0104', '2005-01-30', 'hash_placeholder_4', 'https://picsum.photos/seed/mia/200',     'Las Vegas',  'NV', TRUE),
('kchen',      'Kevin',   'Chen',     'kchen4@byu.edu',     '801-555-0105', '2004-06-09', 'hash_placeholder_5', 'https://picsum.photos/seed/kevin/200',   'Seattle',    'WA', TRUE);

INSERT INTO id_verifications (user_id, document_type, document_image_url, status, reviewed_at) VALUES
(1, 'drivers_license', 'https://example.com/ids/1.jpg', 'verified', NOW()),
(2, 'drivers_license', 'https://example.com/ids/2.jpg', 'verified', NOW()),
(3, 'byu_student_id',  'https://example.com/ids/3.jpg', 'verified', NOW()),
(4, 'byu_student_id',  'https://example.com/ids/4.jpg', 'pending',  NULL),
(5, 'byu_student_id',  'https://example.com/ids/5.jpg', 'verified', NOW());

INSERT INTO destinations (destination_name, city, state, category, photo_url, est_drive_minutes, est_price_per_rider) VALUES
('Salt Lake City',       'Salt Lake City', 'UT', 'City trip',     'https://picsum.photos/seed/slc/600/400',     50, 8.00),
('Park City',            'Park City',      'UT', 'Ski trip',      'https://picsum.photos/seed/parkcity/600/400', 60, 10.00),
('Moab / Arches',        'Moab',           'UT', 'National park', 'https://picsum.photos/seed/moab/600/400',    210, 25.00),
('St. George / Zion',    'St. George',     'UT', 'National park', 'https://picsum.photos/seed/zion/600/400',    225, 28.00),
('Las Vegas',            'Las Vegas',      'NV', 'Weekend getaway','https://picsum.photos/seed/vegas/600/400',  330, 35.00);

INSERT INTO trips (driver_id, destination_id, departure_location, departure_time, return_time, total_seats, seats_available, price_per_seat, trip_notes, trip_status) VALUES
(1, 3, 'Wilkinson Student Center, Provo', '2026-10-16 08:00-06', '2026-10-17 18:00-06', 4, 2, 25.00, 'Hiking Delicate Arch Saturday. Room for small bags only.', 'open'),
(2, 2, 'Helaman Halls parking lot',       '2026-10-24 07:00-06', '2026-10-24 17:00-06', 3, 3, 10.00, 'Day trip, leaving early.', 'open'),
(1, 1, 'Tanner Building, Provo',          '2026-10-11 12:00-06', '2026-10-11 20:00-06', 4, 0, 8.00,  'Jazz game. Full.', 'full'),
(5, 4, 'Wyview Park, Provo',              '2026-11-06 14:00-07', '2026-11-08 16:00-07', 3, 3, 28.00, 'Zion over the weekend, splitting gas.', 'open');

INSERT INTO seat_requests (trip_id, rider_id, seats_requested, request_message, request_status, responded_at) VALUES
(1, 3, 1, 'Can I bring a day pack?',    'accepted', NOW()),
(1, 4, 1, 'Excited to go!',             'accepted', NOW()),
(1, 5, 1, NULL,                         'pending',  NULL),
(3, 2, 2, 'Me and my roommate',         'accepted', NOW()),
(3, 3, 2, NULL,                         'accepted', NOW()),
(2, 4, 1, 'First time skiing, haha',    'denied',   NOW());

INSERT INTO chat_messages (trip_id, sender_id, message_body) VALUES
(1, 1, 'Welcome! Meet at the WILK at 7:50.'),
(1, 3, 'Sounds good, I will bring snacks.'),
(1, 4, 'Is there a spot for a sleeping bag?'),
(3, 1, 'Leaving right at noon, don''t be late!'),
(3, 2, 'We will be there.');
