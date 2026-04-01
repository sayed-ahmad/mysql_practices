/*****************
Subqueries, CTEs, Temp. Tables - Solutions
*****************/


USE atlas;

-- 1. How many more Impressionism paitings are there than Rococo paintings?
SELECT 
	(SELECT COUNT(*) FROM works WHERE style = 'Impressionism')
    -
    (SELECT COUNT(*) FROM works WHERE style = 'Rococo')
AS ImpressionismRococoDifference;

-- 2. How many canvases have a greater than the average width?
SELECT 
	COUNT(*) AS CanvasesAboveAgerageWidth
FROM 
	canvas_sizes
WHERE
	width > (SELECT AVG(width) FROM canvas_sizes);
            
-- 3. What is the percentage of artists working in each style?
SELECT 
    style, 
    COUNT(*) / (SELECT COUNT(*) FROM artists) * 100 AS PercentageArtists
FROM
    artists
GROUP BY style;

-- 4. Can you check that the column of percentages adds up to 100%?
WITH TableOfPercentages AS (
	SELECT 
		style, 
		COUNT(*) / (SELECT COUNT(*) FROM artists) * 100 AS PercentageArtists
	FROM
		artists
	GROUP BY style
)
SELECT SUM(PercentageArtists)
FROM TableOfPercentages;

-- 5. What is the difference between the greatest number of artists in a style and the least?
SELECT 
	MAX(NumArtists) - MIN(NumArtists) AS RangeOfArtistsByStyle
FROM (
	  SELECT COUNT(*) AS NumArtists 
	  FROM artists
	  GROUP BY style
) AS ArtistCounts;

-- 6. Assuming an artist works at a steady pace over their entire lifetime, what is the average number of paintings produced per year by an artist?
SELECT ROUND(AVG(WorksYearly), 2) AS AvgLifetimeRate
FROM (
    SELECT 
		artist_id,
		COUNT(*) / (death - birth) AS WorksYearly
    FROM 
		works
			JOIN 
		artists USING (artist_id)
    GROUP BY artist_id
) AS LifetimeRateArtists;

/* 7. Which days are the most museums open? We've answered this before, but there's no clear #1. 
Use a subquery or CTE to display *all* the days where the most museums are open. */
SELECT 
	`day`, COUNT(*) AS open_museums
FROM
	museum_hours
GROUP BY `day`
HAVING COUNT(*) = (
		SELECT 
			COUNT(*) AS open_museums
		FROM
			museum_hours
		GROUP BY `day`
		ORDER BY open_museums DESC
        LIMIT 1
);

-- 8. Are there any artists with at least one painting in every museum? 
SELECT 
	COUNT(*) AS artists_in_all_museums
FROM (
	SELECT artist_id, COUNT(DISTINCT museum_id) num_museums
	FROM works 
	GROUP BY artist_id
) AS ArtistMuseumCounts
WHERE 
	num_museums = (SELECT COUNT(*) FROM museums);

-- 9. What percentage of each artist's works are held in a museum? 
WITH ArtistTotalWorks AS (
SELECT 
	artist_id, COUNT(*) AS TotalWorks
FROM
	works
GROUP BY artist_id
)
, ArtistMuseumWorks AS (
SELECT 
    artist_id, 
    COUNT(museum_id) AS InMuseum
FROM 
	works
GROUP BY artist_id
)
SELECT
	artist_id,
    InMuseum / TotalWorks * 100 AS PercInMuseum
FROM
	ArtistTotalWorks
		JOIN
    ArtistMuseumWorks USING (artist_id);

-- 10. What percentage of artists have ALL of their works in a museum?
WITH ArtistTotalWorks AS (
SELECT 
	artist_id, COUNT(*) AS TotalWorks
FROM
	works
GROUP BY artist_id
)
, ArtistMuseumWorks AS (
SELECT 
    artist_id, 
    COUNT(museum_id) AS InMuseum
FROM 
	works
GROUP BY artist_id
)
SELECT
	COUNT(*) AS AllWorksInMuseum
FROM
	ArtistTotalWorks
		JOIN
    ArtistMuseumWorks USING (artist_id)
WHERE 
	TotalWorks = InMuseum;

/*11. Does length of life correlate with the number of paintings created? 
Try grouping artists into age brackets when solving this problem. */
SELECT 
	FLOOR(age / 10) * 10 AS age, 
    AVG(TotalWorks) AS AvgWorks
FROM (
	SELECT artist_id, death - birth AS age, COUNT(*) AS TotalWorks
	FROM works
	JOIN artists USING (artist_id)
	GROUP BY artist_id
) AS ArtistWorksAges
GROUP BY FLOOR(age / 10) * 10
ORDER BY age;

/***** BONUS
Classify museum opening hours as 'Short', 'Medium', or 'Long' based on their length.
Long is 10 hours or more in a day. Short is less than 6 hours.
For each day of the week, count the number of museums open in each category.
e.g. On Monday, 2 museums are open for a short time, 27 are open for a medium time, and 0 are open for a long time.
*****/ 
WITH opening_hours AS (
SELECT 
	museum_id, 
    `day`, 
    STR_TO_DATE(`open`, '%h:%i %p') AS `open`, 
    STR_TO_DATE(`close`, '%h:%i %p') AS `close`,
    TIMESTAMPDIFF(MINUTE, STR_TO_DATE(`open`, '%h:%i %p'), STR_TO_DATE(`close`, '%h:%i %p')) / 60 AS open_hours
FROM museum_hours
)
, labeled_openings AS (
SELECT
	*,
    CASE
		WHEN open_hours > 10 THEN 'Long'
        WHEN open_hours < 6 THEN 'Short'
        ELSE 'Medium'
	END AS opening_category
FROM opening_hours
)
SELECT 
 `day`,
 sum(CASE when opening_category = 'Short' THEN 1 ELSE 0 END) AS short,
 sum(CASE when opening_category = 'Medium' THEN 1 ELSE 0 END) AS `medium`,
 sum(CASE when opening_category = 'Long' THEN 1 ELSE 0 END) AS `long`
 FROM labeled_openings
 group by `day`;