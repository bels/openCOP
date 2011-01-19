--##
ALTER TABLE users ADD COLUMN primary_contact_phone VARCHAR(255);
--$$
--##
CREATE OR REPLACE FUNCTION get_access(
        section_val INTEGER,
        alias_id_val INTEGER
) RETURNS INTEGER AS $$
DECLARE
        read BOOLEAN;
        complete BOOLEAN;
BEGIN
        SELECT
                        bool_or(section_aclgroup.aclread)
        INTO read
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
                        not deleted;

	SELECT
                        bool_or(section_aclgroup.aclcomplete)
	INTO complete
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
			not deleted;

	IF complete THEN
		RETURN 1;
	ELSIF read THEN
		RETURN 2;
	ELSE
		RETURN 0;
	END IF;
	RETURN -1;
END;
$$ LANGUAGE plpgsql;
--$$
--##
CREATE OR REPLACE VIEW friendly_helpdesk AS
	SELECT
		ticket,
		st.status AS status,
		h.status AS status_id,
		barcode,
		si.name AS site,
		h.site AS site_id,
		location,
		requested,
		updated,
		author,	
		contact,
		contact_phone,
		notes,
		s.name AS section,
		h.section AS section_id,
		problem,
		p.description AS priority,
		h.priority AS priority_id,
		serial,
		u.alias AS updater,
		h.updater AS updater_id,
		contact_email,
		u.alias AS technician,
		h.technician AS technician_id,
		u.alias AS submitter,
		h.submitter AS submitter_id,
		free_date,
		start_time,
		end_time,
		closed_by,
		completed_by,
		h.active
	FROM
		helpdesk AS h
	JOIN
		section AS s ON h.section = s.id
	JOIN
		priority AS p ON h.priority = p.severity
	JOIN
		status AS st ON h.status = st.id
	JOIN
		users AS u ON h.technician = u.id
	JOIN
		site AS si ON h.site = si.id
	;
--$$
--##
CREATE OR REPLACE FUNCTION change_site_level(site_val INTEGER, site_level_val INTEGER) RETURNS VOID AS $$
BEGIN
	UPDATE site SET level = site_level_val WHERE id = site_val;
END;
$$ LANGUAGE plpgsql;
--$$
--##
ALTER TABLE auth ADD COLUMN test TEXT DEFAULT '';
--$$
--##
ALTER TABLE auth ADD COLUMN last_active TIMESTAMP DEFAULT now();
--$$
--##
CREATE OR REPLACE FUNCTION reset_logout(id_val INTEGER) RETURNS INTEGER AS $$
BEGIN
	update auth set last_active = now() where id = id_val;
	RETURN id_val;
END;
$$ LANGUAGE plpgsql;
--$$
--##
CREATE OR REPLACE FUNCTION cleanup_auth() RETURNS INTEGER AS $$
BEGIN
	DELETE FROM auth WHERE (now() - last_active) > '01:00:00';
	RETURN '1';
END;
$$ LANGUAGE plpgsql;
--$$

--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'os'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'cpu'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'description'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'hard_drive'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'ram'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'vendor'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'model'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'ip_address'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'username'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'password'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'role'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'serial'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'domain_name'),(select id from property where property = 'description'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'ip_address'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'vendor'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'model'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'serial'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'description'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'ip_address'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'vendor'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'model'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'serial'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'description'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'ip_address'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'vendor'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'model'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'serial'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'description'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'ip_address'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'vendor'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'model'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'serial'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'description'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'ip_address'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'vendor'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'model'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'serial'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'description'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'vendor'));
--$$
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'ip_address'));
--##
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'description'));
--$$
--##
DROP TYPE IF EXISTS ticket_holder CASCADE;
CREATE TYPE ticket_holder AS (
	ticket INTEGER,
	pid INTEGER,
	name VARCHAR(255),
	status VARCHAR(255),
	priority VARCHAR(255),
	problem TEXT,
	contact VARCHAR(255),
	location VARCHAR(255)
);
--$$
--##
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
				f.priority_id,
				f.section AS name,
				f.priority,
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
				f.priority_id,
				f.section AS name,
				f.priority,
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
--##
--$$
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
	updater_val INTEGER
) RETURNS INTEGER AS $$
DECLARE
	site_val INTEGER;
	section_val INTEGER;
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
			closed_by = closed_by_text,
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
--$$
