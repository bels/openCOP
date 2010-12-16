-- This will remove any data in the database.  I would not recommend using this to recreate tables that got "messed up".  This file should only be used to do an initial creation of the database or to wipe everything and start over.

DROP TABLE IF EXISTS site_level CASCADE;
CREATE TABLE site_level (id SERIAL PRIMARY KEY, type VARCHAR(255) UNIQUE);

DROP TABLE IF EXISTS company CASCADE;
CREATE TABLE company (id SERIAL PRIMARY KEY, name VARCHAR(255), hidden BOOLEAN DEFAULT FALSE);

DROP TABLE IF EXISTS site CASCADE;
CREATE TABLE site (id SERIAL PRIMARY KEY, level INTEGER references site_level(id) ON DELETE CASCADE, name VARCHAR(255), deleted BOOLEAN DEFAULT false, company_id INTEGER references company(id) ON DELETE CASCADE);

DROP TABLE IF EXISTS status CASCADE;
CREATE TABLE status (id SERIAL PRIMARY KEY, status VARCHAR(255));

DROP TABLE IF EXISTS section CASCADE;
CREATE TABLE section (id SERIAL PRIMARY KEY, name VARCHAR(255) UNIQUE, email VARCHAR(255));

DROP TABLE IF EXISTS priority CASCADE;
CREATE TABLE priority (id SERIAL PRIMARY KEY, severity INTEGER, description varchar(255));

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
	id SERIAL PRIMARY KEY,
	first VARCHAR(100),
	last VARCHAR(100),
	middle_initial VARCHAR(100),
	alias VARCHAR(100) UNIQUE,
	email VARCHAR(100),
	password VARCHAR(100),
	active BOOLEAN DEFAULT true,
	site INTEGER DEFAULT null
);

DROP TABLE IF EXISTS helpdesk CASCADE;
CREATE TABLE helpdesk (
	ticket BIGSERIAL PRIMARY KEY,
	status INTEGER references status(id),
	barcode VARCHAR(255),
	site INTEGER references site(id) DEFAULT '1',
	location TEXT,
	requested TIMESTAMP DEFAULT current_timestamp,
	updated TIMESTAMP,
	author TEXT,
	contact VARCHAR(255),
	contact_phone VARCHAR(255),
	notes TEXT,
	section INT DEFAULT '1',
	problem TEXT,
	priority INT DEFAULT '2',
	serial VARCHAR(255),
	updater INTEGER DEFAULT null,
	contact_email VARCHAR(255),
	technician INTEGER DEFAULT '1',
	submitter INTEGER,
	free_date DATE,
	start_time TIME,
	end_time TIME,
	closed_by VARCHAR(255) DEFAULT null,
	completed_by VARCHAR(255) DEFAULT null,
	active BOOLEAN DEFAULT true
);

DROP TABLE IF EXISTS troubleshooting;
CREATE TABLE troubleshooting(id SERIAL PRIMARY KEY, ticket_id INTEGER references helpdesk(ticket), troubleshooting TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS notes;
CREATE TABLE notes(id SERIAL PRIMARY KEY, ticket_id INTEGER references helpdesk(ticket), note TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS auth;
CREATE TABLE auth (id BIGINT, session_key TEXT, created TIMESTAMP DEFAULT current_timestamp, user_id INTEGER references users(id) ,customer BOOLEAN DEFAULT true);

DROP TABLE IF EXISTS reports;
CREATE TABLE reports (id BIGSERIAL PRIMARY KEY, name VARCHAR(255) UNIQUE, report TEXT, owner INTEGER DEFAULT '1', description TEXT DEFAULT null);

DROP TABLE IF EXISTS reports_aclgroup;
CREATE TABLE reports_aclgroup (
	id BIGSERIAL PRIMARY KEY,
	report_id INTEGER references reports(id) ON DELETE CASCADE,
	aclgroup_id INTEGER references aclgroup(id) ON DELETE CASCADE DEFAULT null,
	aclread BOOLEAN DEFAULT false,
	aclupdate BOOLEAN DEFAULT false,
	acldelete BOOLEAN DEFAULT false
);

DROP TABLE IF EXISTS wo;
CREATE TABLE wo(id BIGSERIAL PRIMARY KEY, active BOOLEAN DEFAULT true);

DROP TABLE IF EXISTS wo_name;
CREATE TABLE wo_name(id BIGSERIAL PRIMARY KEY, name VARCHAR(255) UNIQUE);

DROP TABLE IF EXISTS wo_template;
CREATE TABLE wo_template(wo_id INTEGER references wo_name(id) ON DELETE CASCADE, section_id INTEGER references section(id) ON DELETE CASCADE, requires_id INTEGER DEFAULT null, step INTEGER, problem TEXT DEFAULT null);

DROP TABLE IF EXISTS wo_ticket;
CREATE TABLE wo_ticket (id BIGSERIAL PRIMARY KEY, ticket_id INTEGER, requires INTEGER DEFAULT null, wo_id INTEGER, step INTEGER);

DROP TABLE IF EXISTS audit;
CREATE TABLE audit (
	record BIGSERIAL PRIMARY KEY,
	status INTEGER,
	site INTEGER,
	location TEXT,
	updated TIMESTAMP DEFAULT current_timestamp,
	contact VARCHAR(255),
	notes TEXT,
	section INT,
	priority INT,
	tech VARCHAR(255),
	contact_email VARCHAR(255),
	technician INTEGER,
	updater INTEGER,
	ticket INTEGER,
	closed_by VARCHAR(255) DEFAULT NULL,
	completed_by VARCHAR(255) DEFAULT NULL,
	closed_date TIMESTAMP,
	completed_date TIMESTAMP,
	time_worked INTERVAL
);

DROP TABLE IF EXISTS template CASCADE;
DROP TABLE IF EXISTS property CASCADE; 
DROP TABLE IF EXISTS value CASCADE;
DROP TABLE IF EXISTS object CASCADE;
DROP TABLE IF EXISTS template_property;
DROP TABLE IF EXISTS value_property;
DROP TABLE IF EXISTS object_value;
DROP TABLE IF EXISTS object_type;
DROP TABLE IF EXISTS object_company;

CREATE TABLE template (id BIGSERIAL PRIMARY KEY, template VARCHAR(255), UNIQUE (template));

CREATE TABLE property (id BIGSERIAL PRIMARY KEY, property VARCHAR(255), UNIQUE (property));

CREATE TABLE value (id BIGSERIAL PRIMARY KEY, value VARCHAR(255));

CREATE TABLE object (id BIGSERIAL PRIMARY KEY, active BOOLEAN DEFAULT true);

CREATE TABLE template_property (id BIGSERIAL PRIMARY KEY, template_id INTEGER references template(id) ON DELETE CASCADE, property_id INTEGER references property(id) ON DELETE CASCADE);

CREATE TABLE value_property (id BIGSERIAL PRIMARY KEY, property_id INTEGER references property(id) ON DELETE CASCADE, value_id INTEGER references value(id) ON DELETE CASCADE);

CREATE TABLE object_value (id BIGSERIAL PRIMARY KEY, object_id INTEGER references object(id) ON DELETE CASCADE, value_id INTEGER references value(id) ON DELETE CASCADE);

DROP TABLE IF EXISTS aclgroup;
CREATE TABLE aclgroup (id BIGSERIAL PRIMARY KEY, name VARCHAR(255), UNIQUE (name));

DROP TABLE IF EXISTS alias_aclgroup;
CREATE TABLE alias_aclgroup (id BIGSERIAL PRIMARY KEY, alias_id INTEGER references users(id) ON DELETE CASCADE, aclgroup_id INTEGER references aclgroup(id) ON DELETE CASCADE);

DROP TABLE IF EXISTS section_aclgroup;
CREATE TABLE section_aclgroup (id BIGSERIAL PRIMARY KEY, aclgroup_id INTEGER references aclgroup(id) ON DELETE CASCADE, section_id INTEGER references section(id) ON DELETE CASCADE, aclread BOOLEAN DEFAULT false, aclcreate BOOLEAN DEFAULT false, aclupdate BOOLEAN DEFAULT false, aclcomplete BOOLEAN DEFAULT false);

DROP TABLE IF EXISTS enabled_modules;
CREATE TABLE enabled_modules (id SERIAL PRIMARY KEY, module_name VARCHAR(255), filename VARCHAR(255));

-- Default data templates
INSERT INTO template(template) values('server');
INSERT INTO template(template) values('cert');
INSERT INTO template(template) values('domain_name');
INSERT INTO template(template) values('firewall');
INSERT INTO template(template) values('router');
INSERT INTO template(template) values('switch');
INSERT INTO template(template) values('ldap_domain');
INSERT INTO template(template) values('printer');
INSERT INTO template(template) values('wap');
INSERT INTO template(template) values('isp');

-- Default data properties
INSERT INTO property(property) values('type');
INSERT INTO property(property) values('company');
INSERT INTO property(property) values('name');
INSERT INTO property(property) values('po');
INSERT INTO property(property) values('grant_type');
INSERT INTO property(property) values('grant_code');
INSERT INTO property(property) values('description');
INSERT INTO property(property) values('cpu');
INSERT INTO property(property) values('ram');
INSERT INTO property(property) values('hard_drive');
INSERT INTO property(property) values('video_card');
INSERT INTO property(property) values('sound_card');
INSERT INTO property(property) values('vendor');
INSERT INTO property(property) values('model');
INSERT INTO property(property) values('specialty_card');
INSERT INTO property(property) values('username');
INSERT INTO property(property) values('password');
INSERT INTO property(property) values('ip_address');
INSERT INTO property(property) values('role');
INSERT INTO property(property) values('startup_services');
INSERT INTO property(property) values('members');
INSERT INTO property(property) values('rac_address');
INSERT INTO property(property) values('rac_username');
INSERT INTO property(property) values('rac_password');
INSERT INTO property(property) values('vpn_type');
INSERT INTO property(property) values('expiration_date');
INSERT INTO property(property) values('owa_url');
INSERT INTO property(property) values('owa_boolean');
INSERT INTO property(property) values('owa_proxy_address');
INSERT INTO property(property) values('mail_connection_type');
INSERT INTO property(property) values('bis_username');
INSERT INTO property(property) values('bis_password');
INSERT INTO property(property) values('bis_provider');
INSERT INTO property(property) values('special_notes');
INSERT INTO property(property) values('os');
INSERT INTO property(property) values('scan_to_type');
INSERT INTO property(property) values('bandwidth');
INSERT INTO property(property) values('application_version');

-- Adding admin user
INSERT INTO users(alias,email,password,first, last) values('%%ADMIN_USER%%','%%ADMIN_EMAIL%%',MD5('%%ADMIN_PASSWORD%%'),'%%ADMIN_FIRST%%','%%ADMIN_LAST%%');
-- Adding default Helpdesk section.
INSERT INTO section(name,email) values('Helpdesk','helpdesk@email.address'); -- Need to add the ability to change section's email addresses...
-- Adding priorities
INSERT INTO priority(severity,description) values(1,'Low');
INSERT INTO priority(severity,description) values(2,'Normal');
INSERT INTO priority(severity,description) values(3,'High');
INSERT INTO priority(severity,description) values(4,'Business Critical');
-- some starting ticket status
INSERT INTO status (status) values ('New');
INSERT INTO status (status) values ('In Progress');
INSERT INTO status (status) values ('Waiting Customer');
INSERT INTO status (status) values ('Waiting Vendor');
INSERT INTO status (status) values ('Waiting Other');
INSERT INTO status (status) values ('Closed');
INSERT INTO status (status) values ('Completed');

-- Default groups
INSERT INTO aclgroup(name) values('customers');
INSERT INTO aclgroup(name) values('admins');

-- Add admin to the admins group
INSERT INTO alias_aclgroup(alias_id,aclgroup_id) values('1','2');

-- Default permissions
INSERT INTO section_aclgroup (aclgroup_id,section_id,aclread,aclcreate,aclupdate,aclcomplete) values ((select id from aclgroup where name = 'customers'),1,'t','t','t','f');
INSERT INTO section_aclgroup (aclgroup_id,section_id,aclread,aclcreate,aclupdate,aclcomplete) values ((select id from aclgroup where name = 'admins'),1,'t','t','t','t');

DROP TYPE IF EXISTS column_names_holder CASCADE;
CREATE TYPE column_names_holder as (column_name VARCHAR(255));

CREATE OR REPLACE FUNCTION get_column_names(table_val VARCHAR(255)) RETURNS SETOF column_names_holder AS $$
DECLARE
	r column_names_holder%rowtype;
BEGIN
	FOR r IN
		select
			a.attname as column
		from
			pg_catalog.pg_attribute a
		where
			a.attnum > 0
		and
			not a.attisdropped
		and
			a.attrelid = (
				select
					c.oid
				from
					pg_catalog.pg_class c
				left join
					pg_catalog.pg_namespace n
					on n.oid = c.relnamespace
				where
					c.relname = table_val
				and
					pg_catalog.pg_table_is_visible(c.oid)
			)
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE VIEW inventory_temp AS
select
	object.id as object,
	object_value.id as ovid,
	object.active,
	value.value,
	property.property
from
	object
join
	object_value on object.id = object_value.object_id
join
	value on object_value.value_id = value.id
join
	value_property on value.id = value_property.value_id
join
	property on value_property.property_id = property.id;

CREATE OR REPLACE VIEW inventory AS
select
	*
from
	select_object();

DROP TYPE IF EXISTS inventory_temp_holder CASCADE;
CREATE TYPE inventory_temp_holder as (object INTEGER, property VARCHAR(255), value VARCHAR(255));

DROP TYPE IF EXISTS inventory_holder CASCADE;
CREATE TYPE inventory_holder as (id INTEGER, object INTEGER, property VARCHAR(255), value VARCHAR(255));

CREATE OR REPLACE FUNCTION objects(o INTEGER) RETURNS SETOF inventory_holder AS $$
DECLARE
	r inventory_holder%rowtype;
BEGIN
	FOR r IN
		select ovid,object,property,value from inventory_temp where object = o
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION select_object() RETURNS SETOF inventory_temp_holder AS $$
DECLARE
	r inventory_temp_holder%rowtype;
	i integer;
BEGIN
	FOR i IN
		select
			distinct(cast(id as integer))
		from
			object
	LOOP
		FOR r IN
		select
			object,
			property,
			CASE WHEN
				property = 'company'
			THEN
				(select name as company
					from
						company
					join
						inventory_temp
					on
						cast(inventory_temp.value as integer) = company.id where inventory_temp.property = 'company'
					and
						object = i
				)
			WHEN
				property = 'type'
		        THEN
		                (select template as type
	        	                from
	                	                template
	                        	join
		                                inventory_temp
		                        on
	        	                        cast(inventory_temp.value as integer) = template.id where inventory_temp.property = 'type'
					and
					object = i
				)
			ELSE
				value
				END
			from inventory_temp where object = i
		LOOP
			RETURN NEXT r;
		END LOOP;		
	END LOOP;

	return;
END;
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS view_reports_holder CASCADE;
CREATE TYPE view_reports_holder as (id INTEGER, name VARCHAR(255), report VARCHAR(255), owner INTEGER, description TEXT);

CREATE OR REPLACE FUNCTION view_reports(alias_val INTEGER) RETURNS SETOF view_reports_holder AS $$
DECLARE
	r view_reports_holder%rowtype;
BEGIN
	FOR r IN
		select
			distinct(reports.id),
			reports.name,
			reports.report,
			reports.owner,
			reports.description
		from
			reports
		join
			reports_aclgroup
			on
				reports_aclgroup.report_id = reports.id
		where (
				aclgroup_id
				in (
					select
						aclgroup.id
					from
						aclgroup
					join
						alias_aclgroup
						on
							alias_aclgroup.aclgroup_id = aclgroup.id
					where
						alias_aclgroup.alias_id = alias_val
				)
		) and (
				select
		                        bool_or(reports_aclgroup.aclread) as read
		                from
                       			reports_aclgroup
		                where (
                       			(
		                                aclgroup_id
                       			        in (
		                                        select
                       			                        aclgroup.id
		                                        from
                       			                        aclgroup
		                                        join
                       			                        alias_aclgroup
		                                                on
                       			                                alias_aclgroup.aclgroup_id = aclgroup.id
		                                        where
                       			                        alias_aclgroup.alias_id = alias_val
		                                )
                       			)
		                )
		) or (
				reports.owner = alias_val
		)
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_admin_permission() RETURNS TRIGGER AS $$
BEGIN
	IF TG_RELNAME = 'section' THEN
		INSERT INTO section_aclgroup(aclgroup_id,section_id,aclread,aclcreate,aclupdate,aclcomplete) values((select id from aclgroup where name = 'admins'),NEW.id,'t','t','t','t');
	END IF;
	IF TG_RELNAME = 'reports' THEN
		INSERT INTO reports_aclgroup(aclgroup_id,report_id,aclread,aclupdate,acldelete) values((select id from aclgroup where name = 'admins'),NEW.id,'t','t','t');
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_admin_permission ON section;
CREATE TRIGGER insert_admin_permission AFTER INSERT ON section
	FOR EACH ROW EXECUTE PROCEDURE insert_admin_permission();

DROP TRIGGER IF EXISTS insert_admin_permission ON reports;
CREATE TRIGGER insert_admin_permission AFTER INSERT ON reports
	FOR EACH ROW EXECUTE PROCEDURE insert_admin_permission();

CREATE OR REPLACE FUNCTION insert_reports_aclgroup(report_val INTEGER,aclgroup_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO reports_aclgroup(report_id,aclgroup_id,aclread) values(report_val,aclgroup_val,true);
	SELECT INTO last_id currval('reports_aclgroup_id_seq');

	RETURN last_id;	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_reports(report_val VARCHAR(255), name_val VARCHAR(255), owner_val INTEGER, description_val TEXT) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO reports (report,name,owner,description) values(report_val,name_val,owner_val,description_val);
	SELECT INTO last_id currval('reports_id_seq');

	RETURN last_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_object(active_val BOOLEAN) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO object (active) values(active_val);
	SELECT INTO last_id currval('object_id_seq');

	RETURN last_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_object(object_val INTEGER) RETURNS INTEGER AS $$
BEGIN
	DELETE from value where id in (select value_id from object_value where object_value.id = object_val);
	DELETE from object where id = object_val;

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_object_value(value_val VARCHAR(255), property_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	last_value_id INTEGER;
	last_object_id INTEGER;
BEGIN
	INSERT INTO value (value) values(value_val);

	SELECT INTO last_value_id currval('value_id_seq');
	SELECT INTO last_object_id currval('object_id_seq');

	INSERT INTO value_property (property_id,value_id) values(property_val, last_value_id);
	INSERT INTO object_value (object_id,value_id) values(last_object_id, last_value_id);

	RETURN last_value_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_insert_object_value(value_val VARCHAR(255), property_val INTEGER, object_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	last_value_id INTEGER;
BEGIN
	INSERT INTO value (value) values(value_val);

	SELECT INTO last_value_id currval('value_id_seq');

	INSERT INTO value_property (property_id,value_id) values(property_val, last_value_id);
	INSERT INTO object_value (object_id,value_id) values(object_val, last_value_id);

	RETURN last_value_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_object_value(value_val VARCHAR(255), value_id_val INTEGER) RETURNS INTEGER AS $$
BEGIN
	UPDATE value set value = value_val where id = value_id_val;

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_audit_row() RETURNS TRIGGER AS $$
DECLARE
	last_audit INTEGER;
	time_worked_val TIMESTAMP;
BEGIN
	IF TG_OP = 'INSERT' THEN
		INSERT INTO audit (
			status,
			site,
			location,
			contact,
			section,
			priority,
			contact_email,
			technician,
			notes,
			updater,
			ticket
		) values (
			new.status,
			new.site,
			new.location,
			new.contact,
			new.section,
			new.priority,
			new.contact_email,
			new.technician,
			new.notes,
			new.submitter,
			new.ticket
		);
	ELSIF TG_OP = 'UPDATE' THEN
		INSERT INTO audit (
			status,
			site,
			location,
			contact,
			section,
			priority,
			contact_email,
			technician,
			notes,
			updater,
			ticket
		) values (
			new.status,
			new.site,
			new.location,
			new.contact,
			new.section,
			new.priority,
			new.contact_email,
			new.technician,
			new.notes,
			new.updater,
			new.ticket
		);
		IF old.status = '2' THEN
			select into last_audit currval ('audit_record_seq');
			select into time_worked_val updated from audit where ticket = new.ticket and status = '2' order by record desc;
			update audit set time_worked = (current_timestamp - time_worked_val) where record = last_audit;
		END IF;

		IF new.status = '6' THEN
			select into last_audit currval ('audit_record_seq');
			update audit set closed_by = new.closed_by, closed_date = current_timestamp where record = last_audit;
		END IF;

		IF new.status = '7' THEN
			select into last_audit currval ('audit_record_seq');
			update audit set completed_by = new.completed_by, completed_date = current_timestamp where record = last_audit;
		END IF;
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS insert_audit_row ON helpdesk;
CREATE TRIGGER insert_audit_row AFTER INSERT OR UPDATE ON helpdesk
	FOR EACH ROW EXECUTE PROCEDURE insert_audit_row();

CREATE OR REPLACE FUNCTION insert_ticket(
	site_val INTEGER,
	status_val INTEGER,
	barcode_val VARCHAR(255),
	location_val TEXT,
	author_val TEXT,
	contact_val VARCHAR(255),
	contact_phone_val VARCHAR(255),
	troubleshot_val TEXT,
	section_val INTEGER,
	problem_val TEXT,
	priority_val INTEGER,
	serial_val VARCHAR(255),
	contact_email_val VARCHAR(255),
	tech_val INTEGER,
	notes_val TEXT,
	submitter_val INTEGER,
	free_date_val DATE,
	start_time_val TIME,
	end_time_val TIME
) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO helpdesk (
		status,
		barcode,
		site,
		location,
		author,
		contact,
		contact_phone,
		section,
		problem,
		priority,
		serial,
		contact_email,
		technician,
		notes,
		submitter,
		free_date,
		start_time,
		end_time
	) values (
		status_val,
		barcode_val,
		site_val,
		location_val,
		author_val,
		contact_val,
		contact_phone_val,
		section_val,
		problem_val,
		priority_val,
		serial_val,
		contact_email_val,
		tech_val,
		notes_val,
		submitter_val,
		free_date_val,
		start_time_val,
		end_time_val
	);
	SELECT INTO last_id currval('helpdesk_ticket_seq');

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (ticket_id,troubleshooting) values(last_id,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (ticket_id,note) values(last_id,notes_val);
	END IF;

	RETURN last_id;
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
	updater_val INTEGER
) RETURNS INTEGER AS $$
DECLARE
	priority_val INTEGER;
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

CREATE OR REPLACE FUNCTION report_ticket_closure(
	alias_val VARCHAR(255), start_date_val TIMESTAMP, end_date_val TIMESTAMP
) RETURNS INTEGER AS $$
DECLARE
	ticket_count INTEGER;
BEGIN
	select into ticket_count 
		count(ticket)
	from (
		select
			ticket
		from
			audit
		where
			ticket in (
				select
					helpdesk.ticket
				from
					audit
					join
						helpdesk on audit.ticket = helpdesk.ticket
				where (
					helpdesk.closed_by = alias_val
				) and 
					audit.status in ('6','7')
				group by
					helpdesk.ticket
			) and (
				updated between start_date_val and end_date_val
			)
		group by ticket
	) as count;

	return ticket_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION create_wo_name(
	name_val VARCHAR(255)
) RETURNS INTEGER AS $$
DECLARE
	wo_id INTEGER;
BEGIN
	insert into wo_name(
		name
	)
	values(
		name_val
	);

	select into wo_id currval('wo_name_id_seq');
	return wo_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_wo_template(
	wo_val INTEGER,
	section_val INTEGER,
	requires_val INTEGER,
	step_val INTEGER,
	problem_val TEXT
) RETURNS INTEGER AS $$
DECLARE
	wt_id INTEGER;
BEGIN
	insert into wo_template(
		wo_id,
		section_id,
		requires_id,
		step,
		problem
	)
	values(
		wo_val,
		section_val,
		requires_val,
		step_val,
		problem_val
	);
	wt_id := -1;
	return wt_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION is_admin(
	id_val INTEGER
) RETURNS INTEGER AS $$
DECLARE
	is_admin_val INTEGER;
BEGIN
	select into is_admin_val
		count(
			distinct(
				alias_aclgroup.aclgroup_id
			)
		)
	from
		alias_aclgroup
	join
		aclgroup on alias_aclgroup.aclgroup_id = aclgroup.id
	where (
		alias_id = id_val
	) and (
		aclgroup.name = 'admins'
	);
	
	return is_admin_val;
END;
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS agents_working_holder CASCADE;
CREATE TYPE agents_working_holder as (id INTEGER, alias VARCHAR(255), logged_in INTERVAL);

CREATE OR REPLACE FUNCTION agents_working() RETURNS SETOF agents_working_holder AS $$
DECLARE
	r agents_working_holder%rowtype;
BEGIN
	FOR r IN
		select
			id,
			alias,
			(current_timestamp - auth.created) as logged_in
		from
			users
		join
			auth
			on
				users.id = auth.user_id
		where not customer
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_report(report_val INTEGER) RETURNS VARCHAR(255) AS $$
DECLARE
	report_out VARCHAR(255);
BEGIN
	select into report_out (select report from reports where id = report_val);
	return report_out;
END;
$$ LANGUAGE plpgsql;

DROP TYPE IF EXISTS audit_tickets_by_tech_holder CASCADE;
CREATE TYPE audit_tickets_by_tech_holder as (
	record INTEGER,
	time_worked TEXT,
	updated TEXT,
	contact VARCHAR(255),
	notes TEXT,
	contact_email VARCHAR(255),
	ticket INTEGER,
	closed_by VARCHAR(255),
	completed_by VARCHAR(255),
	closed_date TIMESTAMP,
	completed_date TIMESTAMP,
	location TEXT,
	priority VARCHAR(255),
	site VARCHAR(255),
	technician VARCHAR(255),
	updater VARCHAR(255),
	section VARCHAR(255),
	status VARCHAR(255),
	problem TEXT
);

CREATE OR REPLACE FUNCTION audit_tickets_by_tech(user_val INTEGER,ticket_val INTEGER, sd_val TIMESTAMP, ed_val TIMESTAMP) RETURNS SETOF audit_tickets_by_tech_holder AS $$
DECLARE
	r audit_tickets_by_tech_holder%rowtype;
BEGIN
	FOR r IN
		select
			record,
			regexp_replace(cast(time_worked as text),'.[0123456789]+$','') as time_worked,
			to_char(audit.updated,'YYYY-MM-DD HH24:MI:SS') as updated,
			audit.contact,
			audit.notes,
			audit.contact_email,
			audit.ticket,
			audit.closed_by,
			audit.completed_by,
			audit.closed_date,
			audit.completed_date,
			audit.location,
			priority.description as priority,
			site.name as site,
			users.alias as technician,
			users.alias as updater,
			section.name as section,
			status.status as status,
			helpdesk.problem as problem
		from
			audit
		join
			helpdesk
			on
				helpdesk.ticket = audit.ticket
		join
			priority
			on
				priority.id = audit.priority
		join
			site
			on
				site.id = audit.site
		join
			section
			on
				section.id = audit.section
		join
			status
			on
				status.id = audit.status
		join
			users
			on
				users.id = audit.technician
			or
				users.id = audit.updater
		where (
				audit.technician = user_val
			or
				audit.updater = user_val
		) and
			audit.ticket  = ticket_val
		and
			audit.updated between sd_val and ed_val
		
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_tickets_by_ticket(ticket_val INTEGER) RETURNS SETOF audit_tickets_by_ticket_holder AS $$
DECLARE
	r audit_tickets_by_ticket_holder%rowtype;
BEGIN
	FOR r IN
		select
			record,
			regexp_replace(cast(time_worked as text),'.[0123456789]+$','') as time_worked,
			to_char(audit.updated,'YYYY-MM-DD HH24:MI:SS') as updated,
			audit.contact,
			audit.notes,
			audit.contact_email,
			audit.ticket,
			audit.closed_by,
			audit.completed_by,
			audit.closed_date,
			audit.completed_date,
			audit.location,
			priority.description as priority,
			site.name as site,
			users.alias as technician,
			users.alias as updater,
			section.name as section,
			status.status as status,
			helpdesk.problem as problem
		from
			audit
		join
			helpdesk
			on
				helpdesk.ticket = audit.ticket
		join
			priority
			on
				priority.id = audit.priority
		join
			site
			on
				site.id = audit.site
		join
			section
			on
				section.id = audit.section
		join
			status
			on
				status.id = audit.status
		join
			users
			on
				users.id = audit.technician
			or
				users.id = audit.updater
		where
			audit.ticket  = ticket_val
	LOOP
		RETURN NEXT r;
	END LOOP;
	return;
END;
$$ LANGUAGE plpgsql;

-- Permissions and stuff
DROP USER IF EXISTS %%DB_USER%%;
CREATE USER %%DB_USER%% WITH PASSWORD '%%DB_PASSWORD%%';
GRANT SELECT, INSERT, UPDATE, DELETE ON status TO %%DB_USER%%;
GRANT SELECT, UPDATE ON status_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON site_level TO %%DB_USER%%;
GRANT SELECT, UPDATE ON site_level_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON site TO %%DB_USER%%;
GRANT SELECT, UPDATE ON site_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON helpdesk TO %%DB_USER%%;
GRANT SELECT, UPDATE ON helpdesk_ticket_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON priority TO %%DB_USER%%;
GRANT SELECT, UPDATE ON priority_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON section TO %%DB_USER%%;
GRANT SELECT, UPDATE ON section_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO %%DB_USER%%;
GRANT SELECT, UPDATE ON users_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON troubleshooting TO %%DB_USER%%;
GRANT SELECT, UPDATE ON troubleshooting_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO %%DB_USER%%;
GRANT SELECT, UPDATE ON notes_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON company TO %%DB_USER%%;
GRANT SELECT, UPDATE ON company_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON audit TO %%DB_USER%%;
GRANT SELECT, UPDATE ON audit_record_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON template TO %%DB_USER%%;
GRANT SELECT, UPDATE ON template_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON property TO %%DB_USER%%;
GRANT SELECT, UPDATE ON property_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON value TO %%DB_USER%%;
GRANT SELECT, UPDATE ON value_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON object TO %%DB_USER%%;
GRANT SELECT, UPDATE ON object_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON template_property TO %%DB_USER%%;
GRANT SELECT, UPDATE ON template_property_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON value_property TO %%DB_USER%%;
GRANT SELECT, UPDATE ON value_property_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON object_value TO %%DB_USER%%;
GRANT SELECT, UPDATE ON object_value_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON aclgroup TO %%DB_USER%%;
GRANT SELECT, UPDATE ON aclgroup_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON alias_aclgroup TO %%DB_USER%%;
GRANT SELECT, UPDATE ON alias_aclgroup_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON section_aclgroup TO %%DB_USER%%;
GRANT SELECT, UPDATE ON section_aclgroup_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON enabled_modules TO %%DB_USER%%;
GRANT SELECT, UPDATE ON enabled_modules_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON reports TO %%DB_USER%%;
GRANT SELECT, UPDATE ON reports_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON reports_aclgroup TO %%DB_USER%%;
GRANT SELECT, UPDATE ON reports_aclgroup_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON wo TO %%DB_USER%%;
GRANT SELECT, UPDATE ON wo_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON wo_name TO %%DB_USER%%;
GRANT SELECT, UPDATE ON wo_name_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON wo_ticket TO %%DB_USER%%;
GRANT SELECT, UPDATE ON wo_ticket_id_seq TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON wo_template TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory TO %%DB_USER%%;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory_temp TO %%DB_USER%%;
