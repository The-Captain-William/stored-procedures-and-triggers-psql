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
*/



