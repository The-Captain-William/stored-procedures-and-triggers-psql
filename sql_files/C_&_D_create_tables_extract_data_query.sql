-- CODE FOR CREATING TABLES: PART C
CREATE TABLE IF NOT EXISTS quarterly_detailed_report (
	rental_id INT,
	store_id SMALLINT,
	category_id INT,
	film_id INT,
	title VARCHAR(255),
	genre_name VARCHAR(25),
	release_year INT,
	length SMALLINT,
	rating MPAA_RATING,
	rental_rate NUMERIC(4, 2),
	amount_paid NUMERIC(5, 2),
	rental_duration SMALLINT,
	days_rented SMALLINT
);

CREATE TABLE IF NOT EXISTS quarterly_summary_report (
	film_id INT,
	genre_name VARCHAR(25),
	title VARCHAR(255),
	rental_duration SMALLINT,
	times_rented INT,
	times_returned_late INT,
	average_days_rented NUMERIC,
	average_days_returned_late NUMERIC,
	percentage_returned_late NUMERIC(5, 2)
);

-- QUERY FOR EXTRACTING DATA FOR DETAILED: PART D
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
	return_date BETWEEN earlier_date AND later_date
	AND
	return_date IS NOT NULL;
