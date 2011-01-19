DROP TYPE IF EXISTS ticket_holder CASCADE;
CREATE TYPE ticket_holder AS (
	ticket INTEGER,
	priority VARCHAR(255),
	priority_id INTEGER,
	name VARCHAR(255),
	section_id INTEGER,
	status VARCHAR(255),
	status_id VARCHAR(255),
	problem TEXT,
	contact VARCHAR(255),
	location VARCHAR(255)
);
CREATE OR REPLACE FUNCTION lookup_ticket(
	section_val INTEGER,
	alias_id_val INTEGER
) RETURNS SETOF ticket_holder AS $$
DECLARE
	r ticket_holder%rowtype;
	read BOOLEAN;
	complete BOOLEAN;
BEGIN
		SELECT INTO read
				bool_or(section_aclgroup.aclread)
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = section_val
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						alias_aclgroup
					where
						alias_id = alias_id_val
				)
			) and
				not deleted
		;

		SELECT INTO complete
				bool_or(section_aclgroup.aclcomplete)
			from
				section_aclgroup
				join
					section on section.id = section_aclgroup.section_id
				join
					aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
			where
				section_aclgroup.section_id = section_val
			and (
				section_aclgroup.aclgroup_id in (
					select
						aclgroup_id
					from
						alias_aclgroup
					where
						alias_id = alias_id_val
				)
			) and
				not deleted
		;
	IF complete THEN
		FOR r IN
			SELECT
				f.ticket,
				f.priority,
				f.priority_id,
				f.section AS name,
				f.section_id,
				f.status,
				f.status_id,
				f.problem,
				f.contact,
				f.location
			FROM
				friendly_helpdesk AS f
			WHERE
				f.status_id NOT IN ('7')
			AND
				f.active
			AND
				f.section_id = section_val
		LOOP
			RETURN NEXT r;
		END LOOP;
	
	ELSIF read THEN
		FOR r IN
			SELECT
				f.ticket,
				f.priority,
				f.priority_id,
				f.section AS name,
				f.section_id,
				f.status,
				f.status_id,
				f.problem,
				f.contact,
				f.location
			FROM
				friendly_helpdesk AS f
			WHERE
				f.status_id NOT IN ('6','7')
			AND
				f.active
			AND
				f.section_id = section_val
		LOOP
			RETURN NEXT r;
		END LOOP;
	
	ELSE
		RETURN NEXT r;
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION update_ticket(
	ticket_number BIGINT,
	site_text text,
	location_val TEXT,
	contact_val VARCHAR(255),
	contact_phone_val VARCHAR(255),
	troubleshot_val TEXT,
	contact_email_val VARCHAR(255),
	notes_val TEXT,
	status_val INTEGER,
	priority_val INTEGER,
	technician_val INTEGER,
	section_val INTEGER,
	updater_val INTEGER
) RETURNS INTEGER AS $$
DECLARE
	site_val INTEGER;
	last_id INTEGER;
	closed_by_text VARCHAR(255);
	completed_by_text VARCHAR(255);
BEGIN
	--Step 1. Translate priority, site, status, section into values from the other tables
	SELECT INTO site_val id FROM site WHERE name = site_text;
	
	-- Step 2. Update all the columns
	select into closed_by_text alias from users where id = updater_val;
	select into completed_by_text alias from users where id = updater_val;

	IF status_val = '6' THEN
		update helpdesk set
			updated = current_timestamp,
			contact = contact_val,
			contact_phone = contact_phone_val,
			site = site_val,
			location = location_val,
			status = status_val,
			priority = priority_val,
			technician = technician_val,
			section = section_val,
			updater = updater_val
		where ticket = ticket_number;
	ELSIF status_val = '7' THEN
		update helpdesk set
			updated = current_timestamp,
			contact = contact_val,
			contact_phone = contact_phone_val,
			site = site_val,
			location = location_val,
			status = status_val,
			priority = priority_val,
			technician = technician_val,
			section = section_val,
			completed_by = completed_by_text,
			updater = updater_val
		where ticket = ticket_number;
	ELSE
		update helpdesk set
			updated = current_timestamp,
			contact = contact_val,
			contact_phone = contact_phone_val,
			site = site_val,
			location = location_val,
			status = status_val,
			priority = priority_val,
			technician = technician_val,
			section = section_val,
			updater = updater_val
		where ticket = ticket_number;
	END IF;

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (ticket_id,troubleshooting) values(ticket_number,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (ticket_id,note) values(ticket_number,notes_val);
	END IF;
	RETURN ticket_number;
END;
$$ LANGUAGE plpgsql;
