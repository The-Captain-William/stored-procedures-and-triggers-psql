

	
-- 'WRAPPER' FOR Q_SUMMARY_EXTRACT, WHICH IS CALLED BY TRIGGER
-- 'TG_OP -> determining which opperation called the trigger
-- https://www.postgresql.org/docs/15/plpgsql-trigger.html

CREATE OR REPLACE FUNCTION q_summary_refresh()
RETURNS TRIGGER AS
$$
DECLARE
	film_id_param INT;
BEGIN
	IF TG_OP = 'INSERT' THEN
		film_id_param = NEW.film_id;
		
	ELSIF TG_OP = 'UPDATE' THEN
		film_id_param = NEW.film_id;
		
	ELSIF TG_OP = 'DELETE' THEN
		film_id_param = OLD.film_id;
	END IF;

	CALL q_summary_extract(film_id_param);
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;



-- ACTUAL TRIGGER
-- 1. TRIGGER CALLS REFRESH
-- 2. REFRESH CHECKS WHAT SET OFF THE TRIGGER
-- 3. REFRESH APPLIES PROPER ARGUMENT TO Q_SUMMARY_EXTRACT; THEN FIRES Q_SUMMARY_EXTRACT


CREATE OR REPLACE TRIGGER detailed_updated_inserted_or_deleted
AFTER INSERT OR UPDATE OR DELETE
ON quarterly_detailed_report
FOR EACH ROW
EXECUTE FUNCTION q_summary_refresh();



CALL q_summary_refresh(1000);


