-- 3.3.1 Subquery using IN.
--       Requirement: IN.
SELECT r.renter_id,
       r.renter_name
FROM renters r
WHERE r.renter_id IN (
    SELECT v.renter_id
    FROM viewings v
    WHERE v.viewing_status = 'disputed'
)
ORDER BY r.renter_id;

-- 3.3.2 Common Table Expression using WITH.
--       Requirement: CTE.
WITH disputed_renters AS (
    SELECT DISTINCT v.renter_id
    FROM viewings v
    WHERE v.viewing_status = 'disputed'
)
SELECT r.renter_id,
       r.renter_name
FROM renters r
JOIN disputed_renters dr ON dr.renter_id = r.renter_id
ORDER BY r.renter_id;

-- 3.3.3 Set-based approach using INTERSECT.
--       Requirement: INTERSECT.
(SELECT r.renter_id,
       r.renter_name
FROM renters r)
INTERSECT
SELECT r.renter_id,
       r.renter_name
FROM renters r
JOIN viewings v ON v.renter_id = r.renter_id
WHERE v.viewing_status = 'disputed'
ORDER BY renter_id;

-- 3.3.4 Prove the three forms return identical rows, not just identical
--       counts: the symmetric difference between each pair should be empty.
WITH via_in AS (
    SELECT r.renter_id
    FROM renters r
    WHERE r.renter_id IN (
        SELECT v.renter_id FROM viewings v WHERE v.viewing_status = 'disputed'
    )
),
via_cte AS (
    SELECT r.renter_id
    FROM renters r
    JOIN (
        SELECT DISTINCT v.renter_id
        FROM viewings v
        WHERE v.viewing_status = 'disputed'
    ) dr ON dr.renter_id = r.renter_id
),
via_intersect AS (
    SELECT r.renter_id
    FROM renters r
    INTERSECT
    SELECT r.renter_id
    FROM renters r
    JOIN viewings v ON v.renter_id = r.renter_id
    WHERE v.viewing_status = 'disputed'
)
(SELECT renter_id FROM via_in EXCEPT SELECT renter_id FROM via_cte)
UNION ALL
(SELECT renter_id FROM via_cte EXCEPT SELECT renter_id FROM via_in)
UNION ALL
(SELECT renter_id FROM via_in EXCEPT SELECT renter_id FROM via_intersect)
UNION ALL
(SELECT renter_id FROM via_intersect EXCEPT SELECT renter_id FROM via_in);
-- Expected: 0 rows.

/*
Where the three would NOT be equivalent: duplicates.

via_in and via_intersect just ask "does this renter show up in a disputed viewing, yes or no?"

via_cte works differently. It lines up each renter next to every one of their disputed viewings. 

In our data, renter 5 has three disputed viewings and renter 16 has two. 
So if via_cte forgot its DISTINCT, it would list renter 5 three times and 
renter 16 twice, while via_in and via_intersect would each still only list them once. 
The three "forms" would no longer agree on what the result looks like.
*/