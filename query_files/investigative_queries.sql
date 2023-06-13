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
ORDER BY 2 ASC;


