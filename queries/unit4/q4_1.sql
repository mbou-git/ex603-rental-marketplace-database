-- 4.1.1 Show the overall count, total, average, min, and max duration
--       across all viewings, plus how many distinct renters show up.
--       Requirement: COUNT, SUM, AVG, MIN, MAX, COUNT DISTINCT.
SELECT COUNT(*)                    AS viewings_count,
       SUM(v.duration_min)         AS total_duration_min,
       AVG(v.duration_min)         AS avg_duration_min,
       MIN(v.duration_min)         AS min_duration_min,
       MAX(v.duration_min)         AS max_duration_min,
       COUNT(DISTINCT v.renter_id) AS distinct_renters
FROM viewings v;

-- 4.1.2 Show how many viewings each property got and their average
--       duration, busiest property first.
--       Requirement: GROUP BY, COUNT, AVG, ORDER BY.
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS viewings_count,
       AVG(v.duration_min) AS avg_duration_min
FROM properties p
         LEFT JOIN viewings v ON v.property_id = p.property_id
GROUP BY p.property_id, p.property_label
ORDER BY viewings_count DESC;

-- 4.1.3 Same as 4.1.2, but only for properties with enough viewings for
--       their numbers to mean anything.  Busiest property first.
--       Threshold: 10. There's a natural gap in the data between 6 and 11
--       viewings for a property, so 10 is a reasonable threshold for "enough".
--       Requirement: GROUP BY, HAVING.
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS viewings_count,
       AVG(v.duration_min) AS avg_duration_min
FROM properties p
         LEFT JOIN viewings v ON v.property_id = p.property_id
GROUP BY p.property_id, p.property_label
HAVING COUNT(v.viewing_id) >= 10
ORDER BY viewings_count DESC;

-- 4.1.4 Break viewings down by property city (region) and status
--       together, one row per combination, so regional leaders can see
--       their own area's outcome mix.
--       Requirement: GROUP BY two columns.
SELECT p.city,
       v.viewing_status,
       COUNT(*)            AS viewings_count,
       AVG(v.duration_min) AS avg_duration_min
FROM properties p
         JOIN viewings v ON v.property_id = p.property_id
GROUP BY p.city, v.viewing_status
ORDER BY p.city, v.viewing_status;
