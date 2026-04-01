/*****************
Maths - Solutions
*****************/


USE atlas;

-- 1. What's the difference between the largest and the smallest regular price?
SELECT 
    MAX(regular_price) - MIN(regular_price)
FROM
    product_prices;

-- 2. What is the difference between the earliest birth and latest death?
SELECT 
    MAX(death) - MIN(birth)
FROM
    artists;

-- 3. What is the average age of an artist at death?
SELECT 
    AVG(death - birth)
FROM
    artists;

-- 4. What is the average difference between regular and sale price of a 'Rococo' work, rounded to 2 decimal places?
SELECT 
    ROUND(AVG(regular_price - sale_price), 2)
FROM
    product_prices
        JOIN
    works USING (work_id)
WHERE
    style = 'Rococo';

-- 5. What is the average age at death of a 'Rococo' artist, rounded down to the nearest integer?
SELECT 
    FLOOR(AVG(death - birth))
FROM
    artists
WHERE
    style = 'Rococo';

-- 6. What is the average age at death of a 'Rococo' artist, rounded up to the nearest integer?
SELECT 
    CEIL(AVG(death - birth))
FROM
    artists
WHERE
    style = 'Rococo';

/* 7. What is the total length of time each style had living artists, expressed in decades? 
Take the total length as the difference between the earliest birth and latest death of all artists in that style.
Round up to the nearest 10 years.Order the results from largest to smallest length of time. */
SELECT 
    style, CEIL((MAX(death) - MIN(birth)) / 10) AS decades_practiced
FROM
    artists
GROUP BY style;

-- 8. How many canvases have an area between 600 and 1000 square inches?
SELECT 
    COUNT(*) AS num_canvases
FROM
    canvas_sizes
WHERE
    width * height BETWEEN 600 AND 1000;

-- 9. If it costs $11.27 to visit each museum, how much would it cost to visit all museums with 'Rococo' paintings?
SELECT 
    COUNT(DISTINCT museum_id) * 11.27 AS total_cost
FROM
    works
WHERE
    style = 'Rococo';

-- 10. How many more artists are there than subjects?
SELECT 
    COUNT(DISTINCT artist_id) - COUNT(DISTINCT subject) AS diff_artists_subjects
FROM
    artists
        JOIN
    works USING (artist_id)
        JOIN
    subjects USING (work_id);

-- 11. Which 'Cubist' artists have an odd number of works?
SELECT 
    full_name, 
    COUNT(*) AS num_paintings
FROM
    works
        JOIN
    artists a USING (artist_id)
WHERE
    a.style = 'Cubist'
GROUP BY artist_id
HAVING MOD(COUNT(*), 2) = 1;

-- 12. What is the average canvas size, rounded to the nearest square inch?
SELECT 
    ROUND(AVG(width * height), 0) AS avg_size
FROM
    canvas_sizes;

/***** BONUS
Opening and closing hours are human readable, but lack a proper numerical format. 
Find a way to convert them to a suitable format.
If successful, you can calculate how many hours museums are open each day.
You may find this page useful: https://dev.mysql.com/doc/refman/8.4/en/date-and-time-functions.html 
*****/ 
SELECT 
	museum_id, 
    `day`, 
    STR_TO_DATE(`open`, '%h:%i %p') AS `open`, 
    STR_TO_DATE(`close`, '%h:%i %p') AS `close`,
    TIMESTAMPDIFF(MINUTE, STR_TO_DATE(`open`, '%h:%i %p'), STR_TO_DATE(`close`, '%h:%i %p')) / 60 AS open_hours
FROM museum_hours;