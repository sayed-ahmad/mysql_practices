/*****************
Stored Procedures - Solutions
*****************/


USE atlas;

-- 1. Create a view help track of museum rankings by number of paintings they have.
CREATE VIEW MuseumsPaintingsRanked AS
SELECT
	m.`name`,
    COUNT(*) AS NumWorks,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS MuseumRank
FROM
	museums m
	JOIN works USING (museum_id)
GROUP BY museum_id
ORDER BY MuseumRank;

SELECT *
FROM MuseumsPaintingsRanked;	

-- 2. Create a view help your colleagues see how many museums are open every day.
CREATE VIEW daily_open_museums AS 
SELECT `day`, COUNT(*) AS open_museums_count
FROM museum_hours
GROUP BY `day`;

SELECT * FROM daily_open_museums;

/* 3. Create a view showing the most popular (most paintings in museums) artist 
in each country. Order the results from highest number of paintings to lowest. 
Ignore results where fewer than three paintings have been collected. */
CREATE VIEW top_artists_by_country AS
WITH artist_ranks_countries AS (
SELECT 
	country, 
	full_name, 
    COUNT(*) AS paintings_in_museums,
	RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS artist_rank
FROM 
	artists 
		JOIN 
    works USING (artist_id) 
		JOIN 
    museums USING (museum_id)
GROUP BY country, artist_id
HAVING COUNT(*) > 2
)
SELECT country, full_name, paintings_in_museums 
FROM artist_ranks_countries 
WHERE artist_rank = 1
ORDER BY paintings_in_museums DESC;

SELECT * FROM top_artists_by_country;

/* 4. Create a stored procedure that, when provided with a style, 
retrieves all artists and their works associated with the style */
DELIMITER $$

CREATE PROCEDURE GetAllInStyle (IN InputStyle VARCHAR(20))
BEGIN
SELECT a.style AS artist_style,
	full_name AS artist_name,
    `name` AS painting_name,
    w.style AS painting_style
 FROM works w JOIN artists a USING (artist_id)
WHERE InputStyle IN (a.style, w.style);
END $$

DELIMITER ;

CALL GetAllInStyle('Impressionism');

-- 5. Create a stored procedure to look up all of the works held by a museum.
DELIMITER $$

CREATE PROCEDURE GetAllWorksInMuseum (IN InputName VARCHAR(50))
BEGIN
SELECT full_name, w.`name`, w.style, nationality, il.url
FROM works w 
JOIN museums m USING (museum_id) 
JOIN artists USING (artist_id)
JOIN image_links il USING (work_id)
WHERE m.`name` = InputName;
END$$

DELIMITER ;

CALL GetAllWorksInMuseum('National Gallery');

-- 6. Create a stored procedure to fetch museums open on given a day and time
/***** 
HINT: You can use STR_TO_DATE to easily convert opening and closing times to a proper TIME format.
This should help when checking if the given time falls within the opening hours of a museum. 
https://www.w3schools.com/sql/func_mysql_str_to_date.asp 
*****/
DELIMITER $$

CREATE PROCEDURE open_museums(IN InputDay VARCHAR(10), InputTime VARCHAR(8))
BEGIN
SELECT `name`, address, city, state, postal, country, phone, url, `open`, `close` 
FROM museums 
JOIN museum_hours USING (museum_id)
WHERE 
	`day` = InputDay
		AND
	museum_id IN (
		SELECT museum_id 
		FROM museum_hours 
		WHERE 
			`day` = InputDay 
				AND (
			STR_TO_DATE(InputTime, '%h:%i %p') 
				BETWEEN 
			STR_TO_DATE(`open`, '%h:%i %p') 
				AND 
			STR_TO_DATE(`close`, '%h:%i %p') 
            )
	);
END$$

DELIMITER ;

CALL open_museums('Monday', '9:00 AM');

-- 7. Create a stored function to calculate the maximum price for a work by a given artist.
DELIMITER $$

CREATE FUNCTION max_price_finder (InputName VARCHAR(30))
RETURNS INT
NOT DETERMINISTIC READS SQL DATA

BEGIN
	DECLARE HighestPrice INT;
	SELECT MAX(regular_price) INTO HighestPrice 
	FROM artists 
	JOIN works USING (artist_id)
	JOIN product_prices USING (work_id)
	WHERE full_name RLIKE InputName;

	RETURN HighestPrice;
END$$

DELIMITER ;

SELECT *, max_price_finder(full_name) AS max_price FROM artists LIMIT 10;

-- 8. Create a stored function that returns the most popular (most paintings in museums) artist in a given style
DELIMITER $$

CREATE FUNCTION top_artist_style (InputStyle VARCHAR(20))
RETURNS VARCHAR(80)

NOT DETERMINISTIC READS SQL DATA

BEGIN
DECLARE top_artist VARCHAR(80);
WITH top_artists AS (
	SELECT 
		full_name, 
        birth, 
		RANK() OVER (ORDER BY count(museum_id) DESC) AS artist_rank
	FROM 
		artists AS a
			JOIN 
        works USING (artist_id)
	WHERE 
		a.style = InputStyle 
	GROUP BY artist_id
)
SELECT 
	GROUP_CONCAT(
		CONCAT(full_name, ' (', birth, ')') 
		SEPARATOR ', '
    )INTO top_artist 
FROM 
	top_artists 
WHERE 
	artist_rank = 1;

RETURN top_artist;
END$$

DELIMITER ;

SELECT 
	style, top_artist_style(style) AS MostPopularArtist
FROM (
	SELECT DISTINCT style FROM artists
) AS styles;

-- 9. Create a middle-name finder. Enter an artist's last name (or first and last) to find their middle name.
-- If the artist has no middle name, return 'nameless'
DELIMITER $$

CREATE FUNCTION middle_name_finder(InputName VARCHAR(80))
RETURNS VARCHAR(20)

NOT DETERMINISTIC READS SQL DATA

BEGIN
DECLARE SearchTerm VARCHAR(80);
DECLARE MiddleName VARCHAR(20);
SELECT CONCAT('%', InputName, '%') INTO SearchTerm;
SELECT 
	CASE
		WHEN middle_names IS NOT NULL THEN middle_names
		ELSE 'nameless'
	END INTO MiddleName
FROM artists 
WHERE CONCAT(first_name, ' ', last_name) LIKE SearchTerm;

RETURN MiddleName;
END$$

DELIMITER ;

SELECT middle_name_finder('Sargent');