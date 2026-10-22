-- ---------------------------------------------------------------------
-- Part A: Two numbers in one pass
-- ---------------------------------------------------------------------

-- 4.2a   For each property, total viewings and total failed viewings,
--        computed together in a single pass -- no WHERE filtering the
--        whole query. "Failed" means cancelled or disputed.
--        Requirement: CASE inside an aggregate, SUM(CASE WHEN...).
SELECT p.property_id,
       p.property_label,
       COUNT(v.viewing_id) AS viewings_count,
       SUM(CASE
               WHEN v.viewing_status = 'cancelled' OR v.viewing_status = 'disputed'
                   THEN 1
               ELSE 0
           END)            AS failed_count
FROM properties p
         LEFT JOIN viewings v ON v.property_id = p.property_id
GROUP BY p.property_id, p.property_label
ORDER BY p.property_id;

-- ---------------------------------------------------------------------
-- Part B: Subtotals and a grand total
-- ---------------------------------------------------------------------

-- 4.2b   Viewings and failed viewings per region (city), rolled up to a
--        grand total for the whole platform -- no per-property detail.
--        "Failed" means cancelled or disputed, same definition as Part A.
--        GROUPING() labels the rolled-up row 'All Regions' instead of
--        leaving city as NULL.
--        Requirement: GROUP BY ROLLUP, GROUPING.
--        Note: The five city rows are the regional subtotals.
--              The 'All Regions' row is the platform-wide grand total.
SELECT CASE
           WHEN
               GROUPING(p.city) = 1 THEN 'All Regions'
           ELSE p.city END AS city,
       COUNT(v.viewing_id) AS viewings_count,
       SUM(CASE
               WHEN v.viewing_status = 'cancelled' OR v.viewing_status = 'disputed'
                   THEN 1
               ELSE 0
           END)            AS failed_count
FROM properties p
         LEFT JOIN viewings v ON v.property_id = p.property_id
GROUP BY ROLLUP (p.city)
ORDER BY p.city;

-- ---------------------------------------------------------------------
-- Part C: A two-step pipeline
-- ---------------------------------------------------------------------

-- 4.2c   Step 1: per-property viewing count and failure count.
--        Step 2: filter to high-volume properties (>=10 viewings,
--        same threshold as 4.1.3), then compute their average viewing volume
--        and median failure rate (the actual baseline for evaluating these
--        producers).
--        "* 1.0" forces decimal division (failed_count and viewings_count
--        are both integers, so plain division would truncate to 0).
--        Requirement: WITH producing an intermediate aggregate, then a
--        second aggregation/filter on top of it.
WITH property_stats AS (SELECT p.property_id,
                               p.property_label,
                               COUNT(v.viewing_id) AS viewings_count,
                               SUM(CASE
                                       WHEN v.viewing_status = 'cancelled' OR v.viewing_status = 'disputed'
                                           THEN 1
                                       ELSE 0
                                   END)            AS failed_count
                        FROM properties p
                                 LEFT JOIN viewings v ON v.property_id = p.property_id
                        GROUP BY p.property_id, p.property_label)
SELECT COUNT(*)            AS high_volume_properties,
       AVG(viewings_count) AS average_viewings_per_property,
       PERCENTILE_CONT(0.5) WITHIN GROUP (
           ORDER BY failed_count * 1.0 / viewings_count
           )               AS median_failure_rate_baseline
FROM property_stats
WHERE viewings_count >= 10;

