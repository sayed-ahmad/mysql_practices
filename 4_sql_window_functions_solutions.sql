/*****************
Window Functions - Solutions
*****************/


USE atlas;

-- 1. Rank museums by the number of paitings they have.
SELECT
	m.`name`,
    COUNT(*) AS NumWorks,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS MuseumRank
FROM
	museums m
		JOIN 
    works USING (museum_id)
GROUP BY museum_id
ORDER BY MuseumRank;

-- 2. Select only the top 10 ranked museums from the previous question.
WITH RankedMuseums AS (
	SELECT
		m.`name`,
		COUNT(*) AS NumWorks,
		RANK() OVER (ORDER BY COUNT(*) DESC) AS MuseumRank
	FROM
		museums m
		JOIN works USING (museum_id)
	GROUP BY museum_id
	ORDER BY MuseumRank
)
SELECT *
FROM RankedMuseums
WHERE MuseumRank <= 10;

-- 3. Rank artists in each style based on the total number of paintings made.
SELECT
	a.style,
	full_name,
    COUNT(*) AS WorksMade,
    RANK() OVER (PARTITION BY a.style ORDER BY COUNT(*) DESC) AS Prolificacy
FROM 
	artists a
    JOIN works USING (artist_id)
GROUP BY artist_id;

/* 4. Do the styles museums collect vary by country? What are the top 3 styles for each country?
Ignore countries with fewer than three paintings. */
WITH StyleRanks AS (
SELECT 
	country, 
    style, 
    COUNT(*) AS WorkCount,
	RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS StyleRank
FROM 
	works
		JOIN
    museums USING (museum_id)
WHERE 
	museum_id IS NOT NULL 
GROUP BY country, style
HAVING COUNT(*) > 2
)
SELECT *
FROM StyleRanks 
WHERE StyleRank <= 3;
    
-- 5. We know already on which days the most museums are open. What about the SECOND most?
SELECT 
	`day`, open_museums
FROM
	(SELECT 
		`day`,
		COUNT(*) AS open_museums,
		DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS open_rank
	FROM
		museum_hours
	GROUP BY `day`
	ORDER BY open_museums DESC
) AS table1
WHERE
	open_rank = 2;

-- 6. How many years between the birth of one artist and another?
SELECT
	full_name,
	birth,
    birth - LAG(birth) OVER (ORDER BY birth) as YearsBetweenArtists
FROM 
	artists;
    
/* 7. Arrange canvas sizes by total area. Ignore canvases with only one measurement. 
If two canvases have the same area, display the one with the lower width first.
How much bigger (in area) is each canvas size than the previous? */
SELECT 
	*, 
    width*height AS area, 
    (width*height) - LAG(width*height) OVER (ORDER BY width*height, width) AS area_incrase
FROM 
	canvas_sizes 
WHERE 
	height IS NOT NULL;
    
-- 8. How do the number of paintings created vary century-to-century? Use the artist's death to determine the century.
SELECT 
	FLOOR(death / 100) * 100 AS century, 
    COUNT(*) AS num_paintings,
	COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) AS growth
FROM artists
JOIN works USING (artist_id)
GROUP BY FLOOR(death / 100) * 100;

-- 9. Display the above as a percentage change.
SELECT 
	FLOOR(death / 100) * 100 AS century, 
    COUNT(*) AS num_paintings,
	ROUND((COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100)) / (LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100)) * 100) AS perc_growth
FROM artists
JOIN works USING (artist_id)
GROUP BY FLOOR(death / 100) * 100;

-- 10. Categorise the century-by-century variation by whether it was an increase or decrease compared to the previous century.
SELECT 
	FLOOR(death / 100) * 100 AS century, 
    COUNT(*) AS num_paintings,
	COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) AS growth,
    CASE
		WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) > 0 THEN 'Increase'
        WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) < 0 THEN 'Decrease'
	END cat_growth
FROM artists
JOIN works USING (artist_id)
GROUP BY FLOOR(death / 100) * 100;

-- 11. How many centuries in the data showed an increase in paintings created compared to the previous century?
WITH CenturyGrowthCategorised AS (
SELECT 
	FLOOR(death / 100) * 100 AS century, 
    COUNT(*) AS num_paintings,
	COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) AS growth,
    CASE
		WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) > 0 THEN 'Increase'
        WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) < 0 THEN 'Decrease'
	END cat_growth
FROM artists
JOIN works USING (artist_id)
GROUP BY FLOOR(death / 100) * 100
)
SELECT 
	COUNT(*) AS NumPosGrowthCenturies
FROM 
	CenturyGrowthCategorised
WHERE 
	cat_growth = 'Increase';

-- 12. Display the above as a percentage of all centuries except the first in the dataset.
WITH CenturyGrowthCategorised AS (
SELECT 
	FLOOR(death / 100) * 100 AS century, 
    COUNT(*) AS num_paintings,
	COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) AS growth,
    CASE
		WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) > 0 THEN 'Increase'
        WHEN COUNT(*) - LAG(COUNT(*)) OVER (ORDER BY FLOOR(death / 100) * 100) < 0 THEN 'Decrease'
	END cat_growth
FROM artists
JOIN works USING (artist_id)
GROUP BY FLOOR(death / 100) * 100
)
SELECT 
	100 * 
    (SELECT COUNT(*) FROM CenturyGrowthCategorised WHERE cat_growth = 'Increase') /
    (SELECT COUNT(*) FROM CenturyGrowthCategorised WHERE growth IS NOT NULL)
    AS PercentOfCenturiesWithIncrease;

/****** BONUS
Find the artists in the top 1% of works created in a lifetime. 
It may help to find an appropriate window function for this task https://dev.mysql.com/doc/refman/8.4/en/window-function-descriptions.html
******/
SELECT full_name, num_paintings, percentile 
FROM (
	SELECT 
		artist_id, 
        COUNT(*) AS num_paintings, 
		CUME_DIST() OVER (ORDER BY COUNT(*) DESC) AS percentile
	FROM works GROUP BY artist_id
) AS ArtistPercentiles
JOIN artists USING (artist_id)
WHERE percentile <= .01;

/****** BONUS 2
If an employee works open to close every day of the week (starting Monday), 
what day do they need to work until to get a 40-hour week? How many days do they work?
Currently, museum hours are sorted with Sunday first. You can use the custom function 
dayname_to_integer() to help sort the days Monday-Sunday. e.g. dayname_to_integer('Monday') = 1, dayname_to_integer('Tuesday') = 2, etc.
More about custom functions tomorrow!
******/
WITH opening_hours AS (
SELECT 
	museum_id, 
    `day`, 
    STR_TO_DATE(`open`, '%h:%i %p') AS `open`, 
    STR_TO_DATE(`close`, '%h:%i %p') AS `close`,
    TIMESTAMPDIFF(MINUTE, STR_TO_DATE(`open`, '%h:%i %p'), STR_TO_DATE(`close`, '%h:%i %p')) / 60 AS open_hours
FROM museum_hours
)
, TotalHoursWorked AS (
SELECT
	*,
    SUM(open_hours) OVER (PARTITION BY museum_id ORDER BY dayname_to_integer(`day`)) AS TotalHours,
    ROW_NUMBER() OVER (PARTITION BY museum_id ORDER BY dayname_to_integer(`day`)) AS DaysWorked
FROM opening_hours
)
, Over40Hours AS (
SELECT 
	*,
    ROW_NUMBER() OVER (PARTITION BY museum_id) AS row_number_
FROM 
	TotalHoursWorked
WHERE 
	TotalHours >= 40
)
SELECT 
	museum_id,
    `day`,
    TotalHours,
    DaysWorked
FROM 
	Over40Hours
WHERE row_number_ = 1;