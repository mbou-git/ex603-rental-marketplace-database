-- 3.1.1 Find the top 10 active, affordable properties
--       Requirement: WHERE, ORDER BY, LIMIT.
SELECT p.property_id,
       p.property_label,
       p.monthly_rent
FROM properties p
WHERE p.is_available = TRUE
  AND p.monthly_rent <= 2000
ORDER BY p.monthly_rent ASC
LIMIT 10;

-- 3.1.2 Find all possible viewing statuses.
--       Requirement: DISTINCT.
SELECT DISTINCT v.viewing_status
FROM viewings v;

-- 3.1.3a Filter the viewings for viewings that lasted between 15 and 25 minutes
--        Requirement: BETWEEN.
SELECT v.viewing_id,
       v.duration_min
FROM viewings v
WHERE v.duration_min BETWEEN 15 AND 25;

-- 3.1.3b Filter the viewings for viewings that were not attended
--        Requirement: IN.
SELECT v.viewing_id,
       v.viewing_status
FROM viewings v
WHERE v.viewing_status IN ('disputed', 'cancelled');

-- 3.1.4a Find properties numbered 01-09 by matching the label pattern.
--        Requirement: LIKE.
SELECT p.property_id,
       p.property_label
FROM properties p
WHERE p.property_label LIKE 'Property_0%';

-- 3.1.4b Identify cancelled/disputed viewings that are missing a no_show_reason.
--        Requirement: IS NULL.
SELECT v.viewing_id,
       v.viewing_status
FROM viewings v
WHERE v.viewing_status IN ('disputed', 'cancelled')
  AND v.no_show_reason IS NULL;

-- 3.1.4c Show cancelled/disputed viewings with a friendly label standing in
--        for any missing reason.
--        Requirement: COALESCE.
SELECT v.viewing_id,
       v.viewing_status,
       COALESCE(v.no_show_reason, 'No reason provided') AS no_show_reason
FROM viewings v
WHERE v.viewing_status IN ('disputed', 'cancelled');

-- 3.1.5 Label each viewing with a plain-language time of day and interest
--       level, instead of a raw timestamp and a numeric score.
--       Requirement: CASE.
SELECT v.viewing_id,
       v.scheduled_at,
       CASE
           WHEN EXTRACT(HOUR FROM v.scheduled_at) BETWEEN 6 AND 11 THEN 'Morning'
           WHEN EXTRACT(HOUR FROM v.scheduled_at) BETWEEN 12 AND 17 THEN 'Afternoon'
           WHEN EXTRACT(HOUR FROM v.scheduled_at) BETWEEN 18 AND 21 THEN 'Evening'
           ELSE 'Night'
           END AS time_of_day,
       v.interest_score,
       CASE
           WHEN v.interest_score >= 2 THEN 'High interest'
           WHEN v.interest_score >= 1.25 THEN 'Medium interest'
           ELSE 'Low interest'
           END AS interest_level
FROM viewings v
ORDER BY v.interest_score DESC;