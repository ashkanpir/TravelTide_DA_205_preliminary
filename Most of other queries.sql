-- Define user_sessions as sessions within a specific date range
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

-- Calculate user metrics based on their sessions
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

-- Calculate flight-related metrics for users
flight_metrics AS (
    SELECT
        us.user_id,
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,
        AVG(s.flight_discount_amount) AS average_flight_discount,
        SUM(s.flight_discount_amount) / SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon)) AS scaled_ADS_per_km
    FROM user_sessions us
    JOIN sessions s ON us.user_id = s.user_id
    JOIN flights f ON s.trip_id = f.trip_id
    JOIN users u ON s.user_id = u.user_id
    GROUP BY us.user_id, u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon
)

-- Combine user metrics, session data, and flight metrics
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


-- Create a CTE (Common Table Expression) to filter sessions within a specific date range
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

-- Calculate various user metrics based on their sessions
user_metrics AS (
    SELECT
        us.user_id,
        COUNT(DISTINCT us.session_id) AS session_count,  -- Count of unique session IDs
        EXTRACT(DAY FROM MAX(us.session_start) - MIN(us.session_start)) AS recency,  -- Calculate the time span between the earliest and latest sessions
        COUNT(DISTINCT us.session_start) AS frequency,  -- Count of unique session start dates
        SUM(us.page_clicks) AS total_page_clicks,  -- Sum of page clicks
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,  -- Calculate the average proportion of sessions with flight discounts
        AVG(s.flight_discount_amount) AS average_flight_discount,  -- Calculate the average flight discount amount
        SUM(s.flight_discount_amount) / SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon)) AS scaled_ADS_per_km  -- Calculate a scaled metric related to flights per kilometer
    FROM
        user_sessions us
    JOIN
        sessions s ON us.session_id = s.session_id  -- Join with session data
    JOIN
        flights f ON us.trip_id = f.trip_id  -- Join with flight data
    JOIN
        users u ON us.user_id = u.user_id  -- Join with user data
    GROUP BY
        us.user_id
    HAVING
        COUNT(us.session_id) > 7  -- Filter users with more than 7 sessions
)

-- Select and combine user metrics with session, flight, hotel, and user data
SELECT
    um.*,  -- User metrics
    us.*,  -- User sessions
    f.*,  -- Flight data
    h.*,  -- Hotel data
    u.*   -- User data
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

-- Create a CTE (Common Table Expression) to filter sessions within a specific date range
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

-- Calculate various user metrics based on their sessions
user_metrics AS (
    SELECT
        user_id,
          COUNT(DISTINCT session_id) AS session_count,  -- Count of unique session IDs
          EXTRACT(DAY FROM MAX(session_start) - MIN(session_start)) AS recency,  -- Calculate the time span between the earliest and latest sessions
          COUNT(DISTINCT session_start) AS frequency,  -- Count of unique session start dates
          SUM(page_clicks) AS total_page_clicks  -- Sum of page clicks
    FROM
        user_sessions
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT session_id) > 7  -- Filter users with more than 7 sessions
)

-- Select user metrics along with session start and end times
SELECT
    um.*,  -- User metrics
    us.session_start,
    us.session_end
FROM
    user_metrics um
JOIN
    user_sessions us ON um.user_id = us.user_id
    JOIN sessions s ON s.user_id = us.user_id  -- Join with session data
    JOIN hotels h ON s.trip_id = h.trip_id  -- Join with hotel data
    JOIN flights f ON f.trip_id = h.trip_id;  -- Join with flight data

-- Create a CTE (Common Table Expression) to filter sessions within a specific date range
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

-- Calculate various user metrics based on their sessions
user_metrics AS (
    SELECT
        user_id,
        COUNT(DISTINCT session_id) AS session_count,  -- Count of unique session IDs
        EXTRACT(DAY FROM MAX(session_start) - MIN(session_start)) AS recency,  -- Calculate the time span between the earliest and latest sessions
        COUNT(DISTINCT session_start) AS frequency,  -- Count of unique session start dates
        SUM(page_clicks) AS total_page_clicks  -- Sum of page clicks
    FROM
        user_sessions
    GROUP BY
        user_id
    HAVING
        COUNT(DISTINCT session_id) > 7  -- Filter users with more than 7 sessions
)

-- Select user metrics along with session start and end times
SELECT
    um.*,  -- User metrics
    us.session_start,
    us.session_end
FROM
    user_metrics um
JOIN
    user_sessions us ON um.user_id = us.user_id
JOIN
    sessions s ON s.user_id = us.user_id  -- Join with session data
JOIN
    hotels h ON s.trip_id = h.trip_id  -- Join with hotel data
JOIN
    flights f ON f.trip_id = h.trip_id;  -- Join with flight data


-- Create a CTE (Common Table Expression) to count user sessions and filter users with more than 7 sessions
WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(session_id) AS session_count  -- Count sessions per user
    FROM
        sessions
    GROUP BY
        user_id
    HAVING
        COUNT(session_id) > 7  -- Filter users with more than 7 sessions
),

-- Calculate the overall maximum session start date
overall_max AS (
    SELECT MAX(session_start) AS max_session_start FROM sessions
),

-- Calculate user behavior metrics including recency, frequency, and page clicks
F_R_M AS (
    SELECT
        s.user_id,
        EXTRACT(DAY FROM MAX(s.session_start) - om.max_session_start) AS recency,  -- Calculate user recency
        COUNT(s.session_id) AS frequency,  -- Count user session frequency
        SUM(s.page_clicks) AS total_page_clicks,  -- Sum of user page clicks
        NTILE(5) OVER(ORDER BY EXTRACT(DAY FROM MAX(s.session_start) - om.max_session_start) DESC) AS R,  -- Calculate recency quartiles
        NTILE(5) OVER(ORDER BY COUNT(s.session_start)) AS F,  -- Calculate frequency quartiles
        NTILE(5) OVER(ORDER BY SUM(s.page_clicks)) AS P_C  -- Calculate page click quartiles
    FROM
        user_sessions us
    JOIN
        sessions s ON us.user_id = s.user_id
    CROSS JOIN overall_max om
    GROUP BY
        s.user_id, us.session_count, om.max_session_start
    ORDER BY
        frequency DESC, total_page_clicks, recency
),

-- Calculate flight-related metrics
flight_metrics AS (
    SELECT
        s.user_id,
        AVG(CASE WHEN s.flight_discount THEN 1 ELSE 0 END) AS discount_flight_proportion,  -- Calculate the average proportion of sessions with flight discounts
        AVG(s.flight_discount_amount) AS average_flight_discount,  -- Calculate the average flight discount amount
        SUM(s.flight_discount_amount) / 
              SUM(haversine_distance(u.home_airport_lat, u.home_airport_lon, 
                   f.destination_airport_lat, f.destination_airport_lon))
        AS scaled_ADS_per_km  -- Calculate a scaled metric related to flights per kilometer
    FROM
        user_sessions us
    JOIN
        sessions s ON us.user_id = s.user_id
    JOIN
        flights f ON s.trip_id = f.trip_id
    JOIN
        users u ON s.user_id = u.user_id
    WHERE
        s.page_clicks >= 2  -- Filter sessions with at least 2 page clicks
    GROUP BY
        s.user_id, u.home_airport_lat, u.home_airport_lon, f.destination_airport_lat, f.destination_airport_lon
)

-- Select and combine user data, session data, flight data, hotel data, and behavior metrics
SELECT
    u.*,  -- User data
    s.*,  -- Session data
    f.*,  -- Flight data
    h.*,  -- Hotel data
    us.session_count,  -- Session count per user
    fm.discount_flight_proportion,  -- Discounted flight proportion
    fm.average_flight_discount,  -- Average flight discount
    fm.scaled_ADS_per_km,  -- Scaled metric related to flights per kilometer
    COUNT(u.user_id) OVER(PARTITION BY s.user_id) AS repetitive,  -- Count of repetitive users
    R_F_M.recency, R_F_M.frequency, R_F_M.total_page_clicks, R_F_M.R, R_F_M.F, R_F_M.P_C  -- Behavior metrics
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
    session_start >= '2023-01-04' AND session_start <= '2023-07-24'  -- Filter sessions within a specific date range
ORDER BY
    R_F_M.R DESC, R_F_M.F DESC, R_F_M.P_C DESC;  -- Order the results by behavior metrics

-- Create a CTE (Common Table Expression) to count user sessions within a specific date range
WITH user_sessions AS (
    SELECT
        user_id,
        COUNT(session_id) AS session_count  -- Count sessions per user
    FROM
        sessions
    WHERE
        session_start >= '2023-01-04' AND session_start <= '2023-07-23'  -- Filter sessions within a specific date range
    GROUP BY
        user_id
    HAVING
        COUNT(session_id) > 7  -- Filter users with more than 7 sessions
)

-- Select user behavior metrics including recency, frequency, and page clicks
SELECT
    s.user_id,
    EXTRACT(DAY FROM overall_max.max_session_start - MAX(s.session_start)) AS recency,  -- Calculate user recency
    COUNT(s.session_id) AS frequency,  -- Count user session frequency
    SUM(s.page_clicks) AS total_page_clicks,  -- Sum of user page clicks
    NTILE(5) OVER(ORDER BY EXTRACT(DAY FROM MAX(s.session_start) - overall_max.max_session_start) DESC) AS R,  -- Calculate recency quartiles
    NTILE(5) OVER(ORDER BY COUNT(s.session_start)) AS F,  -- Calculate frequency quartiles
    NTILE(5) OVER(ORDER BY SUM(s.page_clicks)) AS P_C,  -- Calculate page click quartiles
    session_start  -- Session start date
FROM
    user_sessions us
JOIN
    sessions s ON us.user_id = s.user_id
CROSS JOIN (
    SELECT MAX(session_start) AS max_session_start FROM sessions  -- Calculate the overall maximum session start date
) AS overall_max
WHERE
    session_start >= '2023-01-04' AND session_start <= '2023-07-23'  -- Filter sessions within a specific date range
GROUP BY
    s.user_id, us.session_count, overall_max.max_session_start, session_start  -- Group by user and session attributes
ORDER BY
    session_start, r DESC, f DESC, p_c DESC;  -- Order the results by session start date and behavior metrics
