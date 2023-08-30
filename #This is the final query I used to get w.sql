#This is the final query I used to get what were needed for clustering. Ostensibly, I had to modify or engineer a lot of the variables. 
-- This CTE combines user information, session details, and flight/hotel data to create a summary of user sessions
WITH UserSessionSummary AS (
    SELECT
        u.user_id,
        EXTRACT(YEAR FROM AGE(u.birthdate)) AS age,
        u.gender,
        u.married::INT,
        u.has_children::INT,
        s.session_id,
        s.session_start,
        s.session_end,
        s.page_clicks,
        s.flight_booked,
        s.hotel_booked,
        s.cancellation,
        s.flight_discount,
        s.hotel_discount,
        s.flight_discount_amount,
        haversine_distance(u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon) AS h_distance,
        f.checked_bags,
        f.base_fare_usd,
        h.hotel_per_room_usd
    FROM
        users u
    JOIN
        sessions s ON u.user_id = s.user_id
    LEFT JOIN
        flights f ON s.trip_id = f.trip_id
    LEFT JOIN
        hotels h ON s.trip_id = h.trip_id
    WHERE
        s.session_start >= '2023-01-04'::DATE
),

-- This CTE counts the total number of sessions per user, filtering out users with less than 8 sessions
SessionCounts AS (
    SELECT
        user_id,
        COUNT(DISTINCT session_id) AS total_sessions
    FROM
        UserSessionSummary
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT session_id) > 7
)

-- This final query aggregates and calculates various metrics based on user session summaries
SELECT
    uss.user_id,
    uss.age,
    uss.gender,
    uss.married,
    uss.has_children,
    sc.total_sessions,
    SUM(uss.page_clicks) AS total_page_clicks,
    AVG(uss.page_clicks::FLOAT) AS avg_page_clicks_per_session,
    AVG(EXTRACT(EPOCH FROM (uss.session_end - uss.session_start))) / 60 AS mean_session_time_minutes,
    SUM(CASE WHEN uss.flight_booked THEN 1 ELSE 0 END) AS total_flights_booked,
    SUM(CASE WHEN uss.hotel_booked THEN 1 ELSE 0 END) AS total_hotels_booked,
    SUM(CASE WHEN uss.cancellation THEN 1 ELSE 0 END) AS total_cancellations,
    AVG(CASE WHEN uss.flight_discount THEN 1 ELSE 0 END) AS avg_flight_discount,
    AVG(CASE WHEN uss.hotel_discount THEN 1 ELSE 0 END) AS avg_hotel_discount,
    SUM(uss.checked_bags) AS total_checked_bags,
    CASE
        WHEN SUM(CASE WHEN uss.flight_booked THEN 1 ELSE 0 END) > 0 THEN
            100.0 * SUM(uss.checked_bags) / SUM(CASE WHEN uss.flight_booked THEN 1 ELSE 0 END)
        ELSE 0.0
    END AS percentage_flights_with_checked_bags,
    AVG(uss.base_fare_usd) AS avg_base_fare_usd,
    AVG(uss.hotel_per_room_usd) AS avg_hotel_per_room_usd,
    SUM(uss.flight_discount_amount) / NULLIF(SUM(uss.h_distance), 0) AS scaled_ads_per_km,
    EXTRACT(DAY FROM AGE(MAX(uss.session_start), CURRENT_DATE)) AS days_since_last_session
FROM
    UserSessionSummary uss
JOIN
    SessionCounts sc ON uss.user_id = sc.user_id
GROUP BY
    uss.user_id, uss.age, uss.gender, uss.married, uss.has_children, sc.total_sessions
ORDER BY
    uss.user_id;
