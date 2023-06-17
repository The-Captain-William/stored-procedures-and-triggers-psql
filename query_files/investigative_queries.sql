SELECT rental.*, amount, (return_date - rental_date) as time_rented
FROM rental JOIN payment USING(rental_id);

-- equate rentals to rating, length, release year


-- how many films are in stock
-- time being rented
-- --don't forget to take into account films that are just sitting on the shelf
SELECT COUNT(film_id) 
FROM inventory
GROUP BY film_id;

SELECT 
	film.*, 
	rental_date, 
	return_date, 
	(return_date - rental_date) as time_rented 
FROM film 
	JOIN inventory ON film.film_id = inventory.film_id
 	JOIN rental ON inventory.inventory_id = rental.inventory_id
	WHERE return_date - rental_date IS NOT NULL 
ORDER BY title ASC, time_rented DESC;


-- potential summary table will include averages
SELECT title, name, rating, AVG(time_rented), COUNT(*) 
FROM (
	SELECT 
	film.*,
	category.name,
	rental_date, 
	return_date, 
	(return_date - rental_date) as time_rented 
FROM category 
	JOIN film_category ON film_category.category_id = category.category_id
	JOIN film ON film.film_id = film_category.film_id
	JOIN inventory ON film.film_id = inventory.film_id
 	JOIN rental ON inventory.inventory_id = rental.inventory_id
	WHERE return_date - rental_date IS NOT NULL 
) AS t
GROUP BY film_id, title, rating, name
ORDER BY 4 DESC;




SELECT film_id, title, count(inventory_id)
FROM film JOIN inventory USING(film_id)
GROUP BY (film_id)
ORDER BY 4;

SELECT film_id, title
FROM film JOIN inventory USING(film_id)
ORDER BY 2;


SELECT MAX(rental_rate) FROM film;

SELECT title, rental_duration, return_date - rental_date AS days_rented, rental_rate, amount AS amount_paid
FROM payment 
JOIN rental USING(rental_id)
JOIN inventory USING (inventory_id)
JOIN film USING (film_id)
WHERE amount > 4.99
ORDER BY 1;

SELECT title, rental_duration, AVG(days_rented), COUNT(*)
FROM (

SELECT title, rental_duration, return_date - rental_date AS days_rented, rental_rate, amount AS amount_paid
FROM payment 
JOIN rental USING(rental_id)
JOIN inventory USING (inventory_id)
JOIN film USING (film_id)
WHERE amount > 4.99
) t
GROUP BY title, rental_duration
ORDER BY 3 DESC, 1 ASC;


SELECT COUNT(*)
FROM payment;

SELECT *, top - bottom 
FROM (
SELECT MAX(rental_date) AS top, MIN(rental_date) AS bottom
FROM rental ) t;

-- last entry was 2006-02-14
-- time gap after 2005-08-23
-- first entry was 2005-5-24
-- can use just last quarter of 2005 
-- 12, 11, 10
SELECT DATE('2005-08-23') - DATE('2005-05-24');


SELECT * 
FROM rental
ORDER BY 2 DESC;

-- selected time period, one un-returned dvd
SELECT * 
FROM rental
WHERE 
	rental_date >= '2005-01-01' AND rental_date <= '2005-12-31'
	AND 
	return_date IS NULL
ORDER BY 2 DESC;

-- selected time period
SELECT * 
FROM rental
WHERE 
	rental_date >= '2005-01-01' AND rental_date <= '2005-12-31'
ORDER BY 2 DESC;

-- could be useful for getting new data
SELECT *
FROM rental
WHERE rental_date BETWEEN (SELECT MAX(rental_date) - INTERVAL '180 days' FROM rental)  AND (SELECT MAX(rental_date) FROM rental)
AND return_date IS NOT NULL;


SELECT * 
FROM rental
ORDER BY return_date DESC;


SELECT * 
FROM rental
WHERE EXTRACT(YEAR FROM rental_date) = '2006'
ORDER BY 2 DESC;



/*
Business Question: 
What are the top performing movies of 
the quarter, which is to be determined by:
- the number of times they were rented
- how long they were rented

side question:

- what percentage were returned late?
- how late were they returned, on average?

- how many if at all, were never returned?

Requirements:
tables:
detailed, summary table

trigger:
trigger to update summary as detailed is modified

stored procedure:
stored procedure to truncate both tables and extract new data

function:
function to modify at least one column in the detailed table

automation:
repeat cycle

Plan:
1. init detailed 
2. function to modify detailed column
3. init summary
4. trigger summary
5. stored procedure to:
		- truncate tables
		A populate detailed
			-- insert into detailed
		- perform aggrigations
		B populate summary
			-- insert into summary
6. automate with events
*/

-- original
SELECT 
	rental.rental_id,
	store_id,
	category.category_id,
	f.film_id,
	f.title,
	category.name AS genre_name,
	f.release_year,
	f.rental_duration,
	f.rental_rate,
	f.length,
	f.rating,
	rental_date, 
	return_date, 
	(return_date - rental_date) as time_rented,
	EXTRACT(DAY FROM return_date - rental_date) AS test,
	payment.amount AS amount_paid
FROM category
	JOIN film_category ON category.category_id = film_category.category_id
	JOIN film f ON f.film_id = film_category.film_id
	JOIN inventory ON f.film_id = inventory.film_id
 	JOIN rental ON inventory.inventory_id = rental.inventory_id
	JOIN payment ON rental.rental_id = payment.rental_id
	WHERE return_date - rental_date IS NOT NULL 
ORDER BY title ASC, time_rented DESC;

----- INITIAL TABLES
-- DETAILED
-- 91 days
-- dates presented are the most solid chunks of time


-- INITIAL TABLE, CREATE DETAILED
DROP TABLE IF EXISTS quarterly_detailed_report;

CREATE TABLE quarterly_detailed_report AS 
	SELECT 
		rental.rental_id,
		store_id,
		category.category_id,
		f.film_id,
		f.title,
		category.name AS genre_name,
		f.release_year,
		f.length,
		f.rating,
		f.rental_rate,
		payment.amount AS amount_paid,
		f.rental_duration,
		return_date - rental_date AS days_rented
	FROM category
		JOIN film_category ON category.category_id = film_category.category_id
		JOIN film f ON f.film_id = film_category.film_id
		JOIN inventory ON f.film_id = inventory.film_id
		JOIN rental ON inventory.inventory_id = rental.inventory_id
		JOIN payment ON rental.rental_id = payment.rental_id
	WHERE 
		return_date BETWEEN '2005-05-24' AND '2005-08-23'
		AND
		return_date IS NOT NULL;

SELECT *, rented_days_elapsed(days_rented) 
FROM quarterly_detailed_report;


-- CREATE FUNCTION 
DROP FUNCTION IF EXISTS rented_days_elapsed;	
	
-- function to return days rented, summing up all days, hours, and minutes with
-- respect to days, and then rounding to a single digit. 
CREATE FUNCTION rented_days_elapsed(
	days_rented INTERVAL
) 
RETURNS SMALLINT AS
$$
	DECLARE days_elapsed SMALLINT;
BEGIN	
	days_elapsed = ROUND(
		(EXTRACT (DAY FROM days_rented) + 
		 EXTRACT (HOUR FROM days_rented)/24 + 
		 EXTRACT(MINUTE FROM days_rented)/(24 * 60)), 0
		);
	RETURN days_elapsed;
END;
$$
LANGUAGE plpgsql;	

-- TEST FUNCTION 
SELECT *, rented_days_elapsed(days_rented) 
FROM quarterly_detailed_report;

-- MODIFY DAYS_RENTED TO GO FROM INTERVAL TO SMALLINT

-- because the column is an entirely *different* datatype, 
-- we have to alter the columns datatype and update values 
-- simultaneously, using the following syntax.

ALTER TABLE quarterly_detailed_report
	ALTER COLUMN days_rented TYPE SMALLINT
	USING rented_days_elapsed(days_rented);

-- VIEW DATA
SELECT *
FROM quarterly_detailed_report;

-- CLEANING DETAILED DATA			

-- there is a mistake in the dataset where multiple rental_id's populate for one
-- specific id, which should not be the case. Each rental_id should be unique,
-- even if a single customer rents multiple DVD's in a given day. 
-- The duplicate is from the payments window. 
-- The best course of action is to delete all of the data related to rental_id 4591,
-- because we can not confirm the accuracy of any given row related to that rental id.


-- delete junk data
DELETE FROM quarterly_detailed_report
WHERE rental_id = 4591;

-- proof all rentals are supposed to be unique even if customer rents same day 
SELECT COUNT(*), customer_id, rental_date
FROM rental
GROUP BY customer_id, rental_date
HAVING COUNT(*) > 1;

-- duplicate entries in payment table only
SELECT COUNT(*) FROM payment
GROUP BY rental_id
HAVING COUNT(*) > 1;

-- mistake in data
SELECT * FROM film
JOIN inventory USING(film_id)
JOIN rental USING(inventory_id)
JOIN payment USING(rental_id)
WHERE rental_id = 4591;

-- checking to make sure 4591 is the only offender 
SELECT rental_id, COUNT(*) AS total
FROM quarterly_detailed_report
GROUP BY rental_id
HAVING COUNT(*) > 1;


SELECT * FROM quarterly_detailed_report
WHERE days_rented IS NULL;

-- SUMMARY TABLE
-- most popular films
-- average rent times
-- number of films returned late
-- average amount of days returned late

SELECT *, days_rented - rental_duration FROM quarterly_detailed_report;

CREATE TABLE quarterly_summary AS 
WITH cte AS (
    SELECT
        q.film_id,
		q.genre_name,
		q.title,
		q.rental_duration,
        COUNT(q.film_id) AS times_rented,
        COUNT(*) FILTER (WHERE q.rental_rate < q.amount_paid) AS times_returned_late,
        ROUND(AVG(q.days_rented), 0) AS average_days_rented,
		COALESCE(ROUND(AVG(q.days_rented - q.rental_duration)  FILTER (WHERE q.rental_rate < q.amount_paid), 0), 0) AS average_days_returned_late
    FROM
        quarterly_detailed_report q
    GROUP BY
        q.film_id, q.title, q.genre_name, q.rental_duration
)

SELECT 
	*, 
    ROUND(CASE 
		  WHEN cte.times_returned_late != 0 THEN (cte.times_returned_late::NUMERIC / cte.times_rented) * 100 
		  ELSE 0 
		  END, 2) AS percentage_returned_late

	  
FROM cte
ORDER BY 5 DESC, 3 ASC;

-- TESTING SUMMARY TABLE
SELECT * FROM quarterly_summary;


-- CREATE STORED PROCEDURE
-- create test db
-- truncate db
-- extract data 

-- create
CREATE TABLE query_detailed_test AS
SELECT * FROM quarterly_detailed_report LIMIT 10;

CREATE TABLE quarterly_summary_test AS 
SELECT * FROM quarterly_summary LIMIT 10;

-- test select
SELECT * FROM query_detailed_test;
SELECT * FROM quarterly_summary_test;

-- truncate
TRUNCATE TABLE query_detailed_test;
TRUNCATE TABLE quarterly_summary_test;

CREATE OR REPLACE PROCEDURE q_detailed_extract()
LANGUAGE plpgsql
AS $$
BEGIN
	-- truncate
	TRUNCATE TABLE query_detailed_test;
	TRUNCATE TABLE quarterly_summary_test;
	
	-- detailed
	INSERT INTO query_detailed_test
		SELECT 
			rental.rental_id,
			store_id,
			category.category_id,
			f.film_id,
			f.title,
			category.name AS genre_name,
			f.release_year,
			f.length,
			f.rating,
			f.rental_rate,
			payment.amount AS amount_paid,
			f.rental_duration,
			rented_days_elapsed(return_date - rental_date) AS days_rented
		FROM category
			JOIN film_category ON category.category_id = film_category.category_id
			JOIN film f ON f.film_id = film_category.film_id
			JOIN inventory ON f.film_id = inventory.film_id
			JOIN rental ON inventory.inventory_id = rental.inventory_id
			JOIN payment ON rental.rental_id = payment.rental_id
		WHERE 
			return_date BETWEEN '2005-05-24' AND '2005-08-23' -- test range
			-- return_date BETWEEN (CURRENT_DATE - INTERVAL '90 days')::DATE AND CURRENT_DATE
			AND
			return_date IS NOT NULL;
	
	-- summary
	INSERT INTO quarterly_summary_test 
		WITH cte AS (
			SELECT
				q.film_id,
				q.genre_name,
				q.title,
				q.rental_duration,
				COUNT(q.film_id) AS times_rented,
				COUNT(*) FILTER (WHERE q.rental_rate < q.amount_paid) AS times_returned_late,
				ROUND(AVG(q.days_rented), 0) AS average_days_rented,
				COALESCE(ROUND(AVG(q.days_rented - q.rental_duration)  FILTER (WHERE q.rental_rate < q.amount_paid), 0), 0) AS average_days_returned_late
			FROM
				query_detailed_test q
			GROUP BY
				q.film_id, q.title, q.genre_name, q.rental_duration
		)

		SELECT 
			*, 
			ROUND(CASE 
				  WHEN cte.times_returned_late != 0 THEN (cte.times_returned_late::NUMERIC / cte.times_rented) * 100 
				  ELSE 0 
				  END, 2) AS percentage_returned_late

		FROM cte
		ORDER BY 5 DESC, 3 ASC;	
			
END;
$$;

CALL q_detailed_extract()

SELECT * FROM query_detailed_test;
SELECT * FROM quarterly_summary_test;


-- 




-- TRIGGER
CREATE TRIGGER q_summary_delete
AFTER DELETE ON quarterly_summary_test
	FOR EACH ROW
	
BEGIN
	SET 
---------
-- correct values for 492, 7 times rented

SELECT * FROM quarterly_detailed_report
WHERE rental_id = 4591 OR film_id =492;

SELECT * FROM quarterly_summary
WHERE film_id = 492;

---------

---------
-- wrong values for 492, 12 times rented
SELECT * FROM query_detailed_test
WHERE rental_id = 4591 OR film_id = 492
ORDER BY 1 ;

SELECT * FROM quarterly_summary_test
WHERE film_id = 492;

DELETE FROM query_detailed_test
	WHERE rental_id = 4591;
--------
