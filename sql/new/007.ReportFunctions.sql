SET SEARCH_PATH TO ticket, public;

CREATE OR REPLACE FUNCTION tickets_received(timeframe INTERVAL) RETURNS TABLE(company_id UUID, company TEXT,amount BIGINT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			c.id,
			c.name,
			count(t.id)
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			t.genesis <= now()
		AND
			t.genesis >= now() - timeframe
		GROUP BY
			c.id;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received(start_date DATE, end_date DATE) RETURNS TABLE(company_id UUID, company TEXT,amount BIGINT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			c.id,
			c.name,
			count(t.id)
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			t.genesis::DATE  >= start_date
		AND
			t.genesis::DATE <= end_date
		GROUP BY
			c.id;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received(timeframe INTERVAL, company_id_val UUID) RETURNS TABLE(id UUID,ticket_id BIGINT, synopsis TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			t.synopsis
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			c.id = company_id_val
		AND
			t.genesis <= now()
		AND
			t.genesis >= now() - timeframe;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received(start_date DATE, end_date DATE, company_id_val UUID) RETURNS TABLE(id UUID,ticket_id BIGINT, synopsis TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			t.synopsis
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			c.id = company_id_val
		AND
			t.genesis::DATE <= end_date
		AND
			t.genesis::DATE >= start_date;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received_per_user(timeframe INTERVAL) RETURNS TABLE(id UUID,company_id UUID, company TEXT,author_name TEXT, contact_name TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			c.id,
			c.name,
			t.author,
			t.contact
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			t.genesis <= now()
		AND
			t.genesis >= now() - timeframe;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received_per_user(start_date DATE, end_date DATE) RETURNS TABLE(id UUID,company_id UUID, company TEXT,author_name TEXT, contact_name TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			c.id,
			c.name,
			t.author,
			t.contact
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			t.genesis::DATE <= end_date
		AND
			t.genesis::DATE >= start_date;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received_per_user(start_date DATE, end_date DATE, company_id_val UUID) RETURNS TABLE(id UUID,company_id UUID, company TEXT,author_name TEXT, contact_name TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			c.id,
			c.name,
			t.author,
			t.contact
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			c.id = company_id_val
		AND
			t.genesis::DATE <= end_date
		AND
			t.genesis::DATE >= start_date;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_received_per_user(timeframe INTERVAL, company_id_val UUID) RETURNS TABLE(id UUID,company_id UUID, company TEXT,client_id UUID, client_name TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			c.id,
			c.name,
			t.author,
			t.contact
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			c.id = company_id_val
		AND
			t.genesis <= now()
		AND
			t.genesis >= now() - timeframe;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_closed(timeframe INTERVAL) RETURNS TABLE(id UUID,ticket_number BIGINT, company_id UUID, company TEXT, technician TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			c.id,
			c.name,
			u.first || ' ' || u.last as name
		FROM
			ticket t
		JOIN
			users u
		ON
			t.technician = u.id
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			(t.status = (select status.id from status where status = 'Closed')
		OR
			t.status = (select status.id from status where status = 'Completed'))
		AND
			t.modified <= now()
		AND
			t.modified >= now() - timeframe;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION tickets_closed(start_date DATE, end_date DATE) RETURNS TABLE(id UUID,ticket_number BIGINT,company_id UUID, company TEXT, technician TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			c.id,
			c.name,
			u.first || ' ' || u.last as name
		FROM
			ticket t
		JOIN
			users u
		ON
			t.technician = u.id
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			(t.status = (select status.id from status where status = 'Closed')
		OR
			t.status = (select status.id from status where status = 'Completed'))
		AND
			t.modified::DATE <= end_date
		AND
			t.modified::DATE >= start_date;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION ticket_time(ticket_id UUID) RETURNS TABLE(id UUID,ticket_number BIGINT, synopsis TEXT,total_time INTERVAL, troubleshooting troubleshooting_time[]) AS $$
DECLARE
	total_troubleshooting troubleshooting_time[];
BEGIN
	SELECT array(select row(t.troubleshooting,time_worked) FROM troubleshooting t WHERE ticket = ticket_id AND t.troubleshooting != '') INTO total_troubleshooting;
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			t.synopsis,
			sum(tr.time_worked),
			total_troubleshooting
		FROM
			ticket t
		JOIN
			troubleshooting tr
		ON
			t.id = tr.ticket
		WHERE
			t.id = ticket_id
		GROUP BY
			t.id, t.synopsis;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE OR REPLACE FUNCTION billable_tickets(timeframe INTERVAL) RETURNS TABLE(id UUID,ticket_number BIGINT, synopsis TEXT, company_name TEXT) AS $$
BEGIN
	RETURN QUERY
		SELECT
			t.id,
			t.ticket,
			t.synopsis,
			c.name
		FROM
			ticket t
		JOIN
			site s
		ON
			t.site = s.id
		JOIN
			company c
		ON
			s.company_id = c.id
		WHERE
			t.genesis <= now()
		AND
			t.genesis >= now() - timeframe
		AND
			t.paid = false
		AND
			t.billable = true;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------