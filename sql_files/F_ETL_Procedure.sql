
DROP TABLE quarterly_detailed_report;
DROP TABLE quarterly_summary;


-- INITIALIZE TABLES OR CLEAR TABLES THAT ALREADY EXIST
CREATE OR REPLACE PROCEDURE quarterly_extraction(earlier_date DATE, later_date DATE)
LANGUAGE plpgsql
AS $$
BEGIN
	/*
	Earlier date, later date are the specified start/stop times that create the time range.
	
	-- TEST Ranges: '2005-05-24' AND '2005-08-23'
	-- PRODUCTION Ranges: (CURRENT_DATE - INTERVAL '90 days')::DATE AND CURRENT_DATE
	*/
	


	-- create
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
	
	-- truncate
	TRUNCATE TABLE  quarterly_detailed_report;
	TRUNCATE TABLE  quarterly_summary_report;	

	
	-- detailed
	INSERT INTO quarterly_detailed_report
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
	
	-- summary
	CALL q_summary_extract(-1);
			
END;
$$;




-- INITIALIZE SUMMARY OR RE-CALCULATE SUMMARY IF SUMMARY UPDATED
CREATE OR REPLACE PROCEDURE q_summary_extract(film_id_param INT)
LANGUAGE plpgsql
AS $$
BEGIN
	/*
	If -1, then don't use any film_id's, truncate and prepare for fresh data.
	Else, only delete and re-calculate where applicable.
	
	NOTE:
	This could also be resolved if quarterly_summary was a materialized view. 
	*/
    IF film_id_param = -1 THEN
        TRUNCATE quarterly_summary_report;
		
    ELSEIF film_id_param != -1 THEN
		DELETE FROM quarterly_summary_report
		WHERE quarterly_summary_report.film_id = film_id_param;
	
	END IF;
	

    -- Insert data into quarterly_summary
    INSERT INTO quarterly_summary_report
    WITH cte AS (
        SELECT
            q.film_id,
            q.genre_name,
            q.title,
            q.rental_duration,
            COUNT(q.film_id) AS times_rented,
            COUNT(*) FILTER (WHERE q.rental_rate < q.amount_paid) AS times_returned_late,
            ROUND(AVG(q.days_rented), 0) AS average_days_rented,
            COALESCE(ROUND(AVG(CASE WHEN q.rental_rate < q.amount_paid THEN q.days_rented - q.rental_duration END), 0), 0) AS average_days_returned_late
        FROM
            quarterly_detailed_report q
        WHERE
            film_id_param = -1 OR q.film_id = film_id_param
        GROUP BY
            q.film_id, q.title, q.genre_name, q.rental_duration
    )
    SELECT 
        *, 
        CASE 
            WHEN times_rented != 0 THEN ROUND((times_returned_late::NUMERIC / times_rented) * 100, 2)
            ELSE 0 
        END AS percentage_returned_late
    FROM
        cte;
END;
$$;

-- TEST
TRUNCATE quarterly_summary;
SELECT * FROM quarterly_summary;
CALL q_summary_extract(1000)

SELECT * FROM quarterly_detailed_report;

-- F.1; FUNCTION FOR PGAGENT
CALL quarterly_extraction((CURRENT_DATE - INTERVAL '90 days')::DATE, CURRENT_DATE);




