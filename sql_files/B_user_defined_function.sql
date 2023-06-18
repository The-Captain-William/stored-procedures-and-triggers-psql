-- CREATE USER DEFINED FUNCTION 

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


