WITH user_sessions AS (
    SELECT
        s.user_id,
        s.session_id,
        s.trip_id,
        s.session_start,
        s.session_end,
        s.page_clicks
    FROM sessions s
    WHERE s.session_start >= '2023-01-04' AND s.session_start <= '2023-07-24'
),

user_metrics AS (
    SELECT
        us.user_id,
        COUNT(DISTINCT us.session_id) AS session_count,
        EXTRACT(DAY FROM MAX(us.session_start) - MIN(us.session_start)) AS recency,
        COUNT(DISTINCT us.session_start) AS frequency,
        SUM(us.page_clicks) AS total_page_clicks
    FROM user_sessions us
    GROUP BY us.user_id
    HAVING COUNT(DISTINCT us.session_id) > 7
),

flight_metrics AS (
    SELECT
        us.user_id,
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,
        AVG(s.flight_discount_amount) AS average_flight_discount,
        SUM(s.flight_discount_amount) / 
  SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon))
  AS scaled_ADS_per_km
    FROM user_sessions us
    JOIN sessions s ON us.user_id = s.user_id
    JOIN flights f ON s.trip_id = f.trip_id
    JOIN users u ON s.user_id = u.user_id
    GROUP BY us.user_id, u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon
)

SELECT
    um.*,
    us.*,
    fm.discount_flight_proportion,
    fm.average_flight_discount,
    fm.scaled_ADS_per_km
FROM user_metrics um
JOIN user_sessions us ON um.user_id = us.user_id
JOIN flight_metrics fm ON um.user_id = fm.user_id
GROUP BY
    um.user_id, um.session_count, um.recency, um.frequency, um.total_page_clicks,
    us.user_id, us.session_id, us.trip_id, us.session_start, us.session_end, us.page_clicks,
    fm.discount_flight_proportion, fm.average_flight_discount, fm.scaled_ADS_per_km;


WITH user_sessions AS (
    SELECT
        s.user_id,
        s.session_id,
        s.trip_id,
        s.session_start,
        s.session_end,
        s.page_clicks
    FROM
        sessions s
    WHERE
        s.session_start >= '2023-01-04' AND s.session_start <= '2023-07-24'
),

user_metrics AS (
    SELECT
        us.user_id,
        COUNT(DISTINCT us.session_id) AS session_count,
        EXTRACT(DAY FROM MAX(us.session_start) - MIN(us.session_start)) AS recency,
        COUNT(DISTINCT us.session_start) AS frequency,
        SUM(us.page_clicks) AS total_page_clicks,
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,
        AVG(s.flight_discount_amount) AS average_flight_discount,
        SUM(s.flight_discount_amount) / 
            SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, 
                f.destination_airport_lat, f.destination_airport_lon))
            AS scaled_ADS_per_km
    FROM
        user_sessions us
    JOIN
        sessions s ON us.session_id = s.session_id
    JOIN
        flights f ON us.trip_id = f.trip_id
    JOIN
        users u ON us.user_id = u.user_id
    GROUP BY
        us.user_id
    HAVING
        COUNT(us.session_id) > 7
)

SELECT
    um.*,
    us.*,
    f.*,
    h.*,
    u.*
FROM
    user_metrics um
JOIN
    user_sessions us ON um.user_id = us.user_id
JOIN
    flights f ON us.trip_id = f.trip_id
JOIN
    hotels h ON us.trip_id = h.trip_id
JOIN
    users u ON um.user_id = u.user_id;


WITH user_sessions AS (
    SELECT
        user_id,
        session_id,
        session_start,
        session_end,
        page_clicks
    FROM
        sessions
    WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-23'
),

user_metrics AS (
    SELECT
        user_id,
          COUNT(DISTINCT session_id) AS session_count,
          EXTRACT(DAY FROM MAX(session_start) - MIN(session_start)) AS recency,
          COUNT(DISTINCT session_start) AS frequency,
          SUM(page_clicks) AS total_page_clicks
    FROM
        user_sessions
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT session_id) > 7
)

SELECT
    um.*,
    us.session_start,
    us.session_end
FROM
    user_metrics um
JOIN
    user_sessions us ON um.user_id = us.user_id
    JOIN sessions s ON s.user_id = us.user_id
    JOIN hotels h ON s.trip_id = h.trip_id
    JOIN flights f ON f.trip_id = h.trip_id;


WITH user_sessions AS (
    SELECT
        user_id,
        session_id,
        session_start,
        session_end,
        page_clicks
    FROM
        sessions
    WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-23'
),

user_metrics AS (
    SELECT
        user_id,
          COUNT(DISTINCT session_id) AS session_count,
          EXTRACT(DAY FROM MAX(session_start) - MIN(session_start)) AS recency,
          COUNT(DISTINCT session_start) AS frequency,
          SUM(page_clicks) AS total_page_clicks
    FROM
        user_sessions
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT session_id) > 7
)

SELECT
    um.*,
    us.session_start,
    us.session_end
FROM
    user_metrics um
JOIN
    user_sessions us ON um.user_id = us.user_id
    JOIN sessions s ON s.user_id = us.user_id
    JOIN hotels h ON s.trip_id = h.trip_id
    JOIN flights f ON f.trip_id = h.trip_id;


WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(session_id) AS session_count
    FROM
        sessions
    GROUP BY
        user_id
    HAVING
        COUNT(session_id) > 7
),

overall_max AS (
    SELECT MAX(session_start) AS max_session_start FROM sessions
),

F_R_M AS (
    SELECT
        s.user_id,
        EXTRACT(DAY FROM MAX(s.session_start) - om.max_session_start) AS recency,
        COUNT(s.session_id) AS frequency,
        SUM(s.page_clicks) AS total_page_clicks,
        NTILE(5) OVER(ORDER BY EXTRACT(DAY FROM MAX(s.session_start) - om.max_session_start) DESC) AS R,
        NTILE(5) OVER(ORDER BY COUNT(s.session_start)) AS F,
        NTILE(5) OVER(ORDER BY SUM(s.page_clicks)) AS P_C
    FROM
        user_sessions us
    JOIN
        sessions s ON us.user_id = s.user_id
    CROSS JOIN overall_max om
    GROUP BY
        s.user_id, us.session_count, om.max_session_start
    ORDER BY frequency DESC, total_page_clicks, recency
),

flight_metrics AS (
    SELECT
        s.user_id,
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,
        AVG(s.flight_discount_amount) AS average_flight_discount,
        SUM(s.flight_discount_amount) / 
              SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, 
                   f.destination_airport_lat, f.destination_airport_lon))
        AS scaled_ADS_per_km
    FROM
        user_sessions us
    JOIN
        sessions s ON us.user_id = s.user_id
    JOIN
        flights f ON s.trip_id = f.trip_id
    JOIN
        users u ON s.user_id = u.user_id
    WHERE
        s.page_clicks >= 2
    GROUP BY
        s.user_id, u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon
)

SELECT
    u.*, s.*, f.*, h.*,
    us.session_count,
    fm.discount_flight_proportion,
    fm.average_flight_discount,
    fm.scaled_ADS_per_km,
    COUNT(u.user_id) OVER(PARTITION BY s.user_id) AS repetitive,
    R_F_M.recency, R_F_M.frequency, R_F_M.total_page_clicks, R_F_M.R, R_F_M.F, R_F_M.P_C
FROM
    users u
JOIN
    user_sessions us ON u.user_id = us.user_id
JOIN
    flight_metrics fm ON u.user_id = fm.user_id
JOIN
    sessions s ON u.user_id = s.user_id
JOIN
    flights f ON s.trip_id = f.trip_id
JOIN
    hotels h ON h.trip_id = s.trip_id
JOIN
    F_R_M R_F_M ON R_F_M.user_id = u.user_id
        WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-24'
ORDER BY R_F_M.R DESC, R_F_M.F DESC, R_F_M.P_C DESC
;


WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(session_id) AS session_count
    FROM
        sessions
    WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-23'
    GROUP BY
        user_id
    HAVING
        COUNT(session_id) > 7
)

SELECT
    s.user_id,
    EXTRACT(DAY FROM overall_max.max_session_start - MAX(s.session_start)) AS recency,
    COUNT(s.session_id) AS frequency,
    SUM(s.page_clicks) AS total_page_clicks,
    NTILE(5) OVER(ORDER BY EXTRACT(DAY FROM MAX(s.session_start) - overall_max.max_session_start) DESC) AS R,
    NTILE(5) OVER(ORDER BY COUNT(s.session_start)) AS F,
    NTILE(5) OVER(ORDER BY SUM(s.page_clicks)) AS P_C,
    session_start
FROM
    user_sessions us
JOIN
    sessions s ON us.user_id = s.user_id
CROSS JOIN (
    SELECT MAX(session_start) AS max_session_start FROM sessions
) AS overall_max
    WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-23'
GROUP BY
    s.user_id, us.session_count, overall_max.max_session_start, session_start
    ORDER BY session_start, r DESC, f DESC, p_c DESC;