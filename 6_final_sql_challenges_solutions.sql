/*****
Expand the database
*****/

/* Find online a dataset that contains the abbreviations for the Brazilian states and the full names of the states. 
It does not need to contain any other information about the states, but it is ok if it does. */

-- Import the dataset as an SQL table in the Magist database.

-- Create the appropriate relationships with other tables in the database.

DROP TABLE IF EXISTS geo_brazilian_state_names;
CREATE TABLE geo_brazilian_state_names (
  brazil_state_id INT NOT NULL AUTO_INCREMENT,
  state varchar(2) NOT NULL,
  state_full_name varchar(20) NOT NULL,
  PRIMARY KEY (brazil_state_id)
);

INSERT INTO geo_brazilian_state_names (
	state_full_name,
	state
)
VALUES
	('Acre', 'AC'),
    ('Alagoas', 'AL'),
    (N'Amapá', 'AP'),
    ('Amazonas', 'AM'),
    ('Bahia', 'BA'),
    (N'Ceará', 'CE'),
    ('Distrito Federal', 'DF'),
    (N'Espírito Santo', 'ES'),
	(N'Goiás', 'GO'),
	(N'Maranhão', 'MA'),
	('Mato Grosso', 'MT'),
	('Mato Grosso do Sul', 'MS'),
	('Minas Gerais', 'MG'),
	(N'Pará', 'PA'),
	(N'Paraíba', 'PB'),
	(N'Paraná', 'PR'),
	('Pernambuco', 'PE'),
	(N'Piauí', 'PI'),
	('Rio de Janeiro', 'RJ'),
	('Rio Grande do Norte', 'RN'),
	('Rio Grande do Sul', 'RS'),
	(N'Rondônia', 'RO'),
	('Roraima', 'RR'),
	('Santa Catarina', 'SC'),
	(N'São Paulo', 'SP'),
	('Sergipe', 'SE'),
	('Tocantins', 'TO');

/*****
Analyze customer reviews
*****/

-- Find the average review score by state of the customer.

SELECT 
    g.state, 
    AVG(o_r.review_score)
FROM
    order_reviews o_r
        JOIN
    orders o USING (order_id)
        JOIN
    customers c USING (customer_id)
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
GROUP BY 
	g.state;

/* Do reviews containing positive words have a better score? 
Some Portuguese positive words are: “bom”, “otimo”, “gostei”, “recomendo” and “excelente”. */
-- Average Review
SELECT 
    AVG(o_r.review_score)
FROM
    order_reviews o_r
        JOIN
    orders o USING (order_id)
        JOIN
    customers c USING (customer_id)
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix;
-- 4.0757

-- AVG Review containing keywords
SELECT 
    AVG(o_r.review_score)
FROM
    order_reviews o_r
        JOIN
    orders o USING (order_id)
        JOIN
    customers c USING (customer_id)
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
WHERE
    o_r.review_comment_message LIKE '%bom%'
        OR o_r.review_comment_message LIKE '%otimo%'
        OR o_r.review_comment_message LIKE '%gostei%'
        OR o_r.review_comment_message LIKE '%recomendo%'
        OR o_r.review_comment_message LIKE '%excelente%';
-- 4.4907

-- Considering only states having at least 30 reviews containing these words, what is the state with the highest score?

SELECT 
    g.state,
    AVG(o_r.review_score) AS avg_review,
    COUNT(DISTINCT(review_id)) AS no_of_reviews
FROM
    order_reviews o_r
        JOIN
    orders o USING (order_id)
        JOIN
    customers c USING (customer_id)
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
WHERE
    o_r.review_comment_message LIKE '%bom%'
        OR o_r.review_comment_message LIKE '%otimo%'
        OR o_r.review_comment_message LIKE '%gostei%'
        OR o_r.review_comment_message LIKE '%recomendo%'
        OR o_r.review_comment_message LIKE '%excelente%'
GROUP BY 
	1
HAVING 
	no_of_reviews >= 30
ORDER BY 
	avg_review DESC;
-- TO, 4.7250

-- What is the state where there is a greater score change between all reviews and reviews containing positive words?

CREATE TEMPORARY TABLE positive_word_reviews
SELECT 
	g.state, 
    AVG(o_r.review_score) as positive_score
FROM 
	order_reviews o_r
		JOIN 
	orders o using (order_id)
		JOIN 
    customers c using (customer_id)
		JOIN 
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
WHERE 
	o_r.review_comment_message LIKE '%bom%'
	OR o_r.review_comment_message LIKE '%otimo%'
	OR o_r.review_comment_message LIKE '%gostei%'
	OR o_r.review_comment_message LIKE '%recomendo%'
	OR o_r.review_comment_message LIKE '%excelente%'
GROUP BY 
	g.state;

SELECT 
    g.state,
    AVG(o_r.review_score) AS avg_review,
    pwr.positive_score,
    (pwr.positive_score - AVG(o_r.review_score)) AS difference
FROM
    order_reviews o_r
        JOIN
    orders o USING (order_id)
        JOIN
    customers c USING (customer_id)
        JOIN
    geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
        JOIN
    positive_word_reviews pwr USING (state)
GROUP BY 
	1
ORDER BY 
	difference DESC
LIMIT 
	1;
-- # state, avg_review, positive_score, difference
-- RR, 3.6087, 4.7143, 1.1056


-- WITH CTE
WITH avg_states_scores as (
  SELECT 
    bs.`name` as `name`, 
    AVG(r.review_score) AS average_review_score 
  FROM 
    order_reviews r 
    LEFT JOIN orders as o USING(order_id) 
    JOIN customers c ON o.customer_id = c.customer_id 
    LEFT JOIN geo as g ON c.customer_zip_code_prefix = g.zip_code_prefix 
    JOIN states bs ON g.state = bs.subdivision 
  GROUP BY 
    bs.`name`
) 
SELECT 
  bs.`name`, 
  avg(o_r.review_score) as avg_good_reviews_score, 
  old_avg.average_review_score as avg_all_reviews_score, 
  avg(o_r.review_score) - old_avg.average_review_score as difference 
FROM 
  order_reviews as o_r 
  LEFT JOIN orders as o USING(order_id) 
  JOIN customers c ON o.customer_id = c.customer_id 
  LEFT JOIN geo as g ON c.customer_zip_code_prefix = g.zip_code_prefix 
  JOIN states bs ON g.state = bs.subdivision 
  LEFT JOIN avg_states_scores as old_avg ON bs.`name` = old_avg.`name` 
WHERE 
  o_r.review_comment_message LIKE '%bom%' 
  OR o_r.review_comment_message LIKE '%otimo%' 
  OR o_r.review_comment_message LIKE '%gostei%' 
  OR o_r.review_comment_message LIKE '%recomendo%' 
  OR o_r.review_comment_message LIKE '%excelente%' 
GROUP BY 
  bs.`name` 
order by 
  difference desc 
limit 
  1;

/*****
Automatize a KPI
*****/

/* Create a stored procedure that gets as input:
The name of a state (the full name from the table you imported).
The name of a product category (in English).
A year
And outputs the average score for reviews left by customers from the given state for orders with the status “delivered, 
containing at least a product in the given category, and placed on the given year. */

DELIMITER $$

CREATE PROCEDURE items_purchased (IN state_full VARCHAR(80), product_english VARCHAR(80), year_ INT)
BEGIN

SELECT 
	AVG(o_r.review_score)
FROM 
	order_reviews o_r
		LEFT JOIN 
	orders o using (order_id)
		LEFT JOIN 
	order_items oi using (order_id)
		LEFT JOIN 
	customers c using (customer_id)
		LEFT JOIN 
	geo g ON c.customer_zip_code_prefix = g.zip_code_prefix
		LEFT JOIN 
	geo_brazilian_state_names bsn using (state)
WHERE 
	o.order_status LIKE 'delivered'
		AND 
	bsn.state_full_name LIKE state_full
		AND 
	YEAR(o.order_purchase_timestamp) = year_
		AND 
	oi.product_id IN (SELECT 
							p.product_id 
					FROM 
						products p
							JOIN 
						product_category_name_translation p_eng  using (product_category_name) 
					WHERE 
						p_eng.product_category_name_english LIKE product_english);

END$$
DELIMITER ;

CALL items_purchased('Rio de Janeiro', 'health_beauty', 2017)
-- 4.0854