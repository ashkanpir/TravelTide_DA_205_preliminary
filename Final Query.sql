#This is the final query I used to get what were needed for clustering. Ostensibly, I had to modify or engineer a lot of the variables. 

WITH cohort AS (
    SELECT
        u.user_id,
        SUM(s.flight_discount_amount * f.base_fare_usd) / NULLIF(SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon)), 0) AS ADS_per_km
    FROM
        users u
    JOIN
        sessions s ON u.user_id = s.user_id
    LEFT JOIN
        flights f ON s.trip_id = f.trip_id
    WHERE
        s.session_start >= '2023-01-04'::DATE
    GROUP BY
        u.user_id
)
SELECT
    u.user_id,
    EXTRACT(YEAR FROM AGE(u.birthdate)) AS age,
    u.gender,
    u.married::INT,
    u.has_children::INT,
    COUNT(DISTINCT s.session_id) AS total_sessions,
    SUM(s.page_clicks) AS total_page_clicks,
    AVG(s.page_clicks::FLOAT) AS avg_page_clicks_per_session,
    AVG(EXTRACT(EPOCH FROM (s.session_end - s.session_start))) AS mean_session_time,
    SUM(CASE WHEN s.flight_booked THEN 1 ELSE 0 END) AS total_flights_booked,
    SUM(CASE WHEN s.hotel_booked THEN 1 ELSE 0 END) AS total_hotels_booked,
    SUM(CASE WHEN s.cancellation THEN 1 ELSE 0 END) AS total_cancellations,
    AVG(s.flight_discount::INT) AS avg_flight_discount,
    AVG(s.hotel_discount::INT) AS avg_hotel_discount,
    SUM(f.checked_bags) AS total_checked_bags,
    CASE
        WHEN SUM(CASE WHEN s.flight_booked THEN 1 ELSE 0 END) > 0 THEN 100 * SUM(f.checked_bags) / SUM(CASE WHEN s.flight_booked THEN 1 ELSE 0 END)
        ELSE 0
    END AS percentage_flights_with_checked_bags,
    AVG(f.base_fare_usd) AS avg_base_fare_usd,
    AVG(h.hotel_per_room_usd) AS avg_hotel_per_room_usd,
    (cohort.ADS_per_km - MIN(cohort.ADS_per_km) OVER ()) / (MAX(cohort.ADS_per_km) OVER () - MIN(cohort.ADS_per_km) OVER ()) AS scaled_ADS_per_km,
    SUM(CASE WHEN s.flight_discount_amount > 0 THEN 1 ELSE 0 END)::FLOAT / COUNT(*) AS discount_flight_proportion,
    MAX(s.session_start) AS last_session_time
    -- Recency: latest session time

FROM
    users u
JOIN
    sessions s ON u.user_id = s.user_id
LEFT JOIN
    flights f ON s.trip_id = f.trip_id
LEFT JOIN
    hotels h ON s.trip_id = h.trip_id
LEFT JOIN
    cohort ON u.user_id = cohort.user_id
WHERE
    s.session_start >= '2023-01-04'::DATE
GROUP BY
    u.user_id, u.birthdate, u.gender, u.married, u.has_children, cohort.ADS_per_km
HAVING
    COUNT(DISTINCT s.session_id) > 7
ORDER BY
    u.user_id;
