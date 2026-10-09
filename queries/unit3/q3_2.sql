-- ---------------------------------------------------------------------
-- Part A: The rows that vanished
-- ---------------------------------------------------------------------
-- 3.2a.1 Column used: viewings.no_show_reason. 

-- 3.2a.2 Find every viewing that wasn't specifically a renter no-show.
--        Requirement: negation/inequality on a nullable column.
SELECT COUNT(*) AS not_renter_no_show
FROM viewings v
WHERE v.no_show_reason != 'Renter no show';

-- 3.2a.3 Find every viewing with no reason recorded at all --> What the first query silently omitted
--        Requirement: IS NULL.
SELECT COUNT(*) AS no_reason_recorded
FROM viewings v
WHERE v.no_show_reason IS NULL;

-- 3.2a.4 The two counts above and the table total, together, so it's
--        visible that they don't sum: total > (3.2a.2) + (3.2a.3).
--        Requirement: demonstrate the shortfall in one result set.
SELECT (SELECT COUNT(*) FROM viewings v)            AS total_viewings,
       (SELECT COUNT(*)
        FROM viewings v
        WHERE v.no_show_reason != 'Renter no show') AS not_renter_no_show,
       (SELECT COUNT(*)
        FROM viewings v
        WHERE v.no_show_reason IS NULL)             AS no_reason_recorded;

-- 3.2a.5 Find every viewing that wasn't specifically a renter no-show. 
--        Includes the viewings with no reason recorded.
--        Requirement: IS NULL.
SELECT COUNT(*) AS not_renter_no_show_fixed
FROM viewings v
WHERE v.no_show_reason != 'Renter no show'
   OR v.no_show_reason IS NULL;

-- ---------------------------------------------------------------------
-- Part B: The alias that did not exist yet
-- ---------------------------------------------------------------------

-- 3.2b.1 Broken: duration_hours is defined in SELECT and referenced in
--        WHERE, where it doesn't exist yet.
--        Requirement: reproduce the alias-in-WHERE error.
SELECT v.viewing_id,
       v.duration_min,
       v.duration_min / 60.0 AS duration_hours
FROM viewings v
WHERE duration_hours > 0.5;

-- Verbatim error message from running 3.2b.1:
-- [42703] ERROR: column "duration_hours" does not exist
--  Position: 114

-- 3.2b.2 Rewrite 1: repeat the expression in WHERE instead of referencing
--        the alias.
--        Requirement: same expression twice.
SELECT v.viewing_id,
       v.duration_min,
       v.duration_min / 60.0 AS duration_hours
FROM viewings v
WHERE v.duration_min / 60.0 > 0.5;

-- 3.2b.3 Rewrite 2: wrap in a CTE, so duration_hours becomes a real column.
--        Requirement: CTE.
WITH viewings_with_hours AS (
    SELECT v.viewing_id,
           v.duration_min,
           v.duration_min / 60.0 AS duration_hours
    FROM viewings v
)
SELECT vh.viewing_id,
       vh.duration_min,
       vh.duration_hours
FROM viewings_with_hours vh
WHERE vh.duration_hours > 0.5;
