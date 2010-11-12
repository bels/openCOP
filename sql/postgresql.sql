-- This will remove any data in the database.  I would not recommend using this to recreate tables that got "messed up".  This file should only be used to do an initial creation of the database or to wipe everything and start over.

DROP TABLE IF EXISTS site_level;
CREATE TABLE site_level (id SERIAL PRIMARY KEY, type VARCHAR(255) UNIQUE(type));

DROP TABLE IF EXISTS company;
CREATE TABLE company (id SERIAL PRIMARY KEY, name VARCHAR(255), hidden BOOLEAN);

DROP TABLE IF EXISTS site;
CREATE TABLE site (id SERIAL PRIMARY KEY, level INTEGER references site_level(id) ON DELETE CASCADE, name VARCHAR(255), deleted BOOLEAN DEFAULT false, company_id INTEGER references company(id) ON DELETE CASCADE);

DROP TABLE IF EXISTS status;
CREATE TABLE status (id SERIAL PRIMARY KEY, status VARCHAR(255));

DROP TABLE IF EXISTS section;
CREATE TABLE section (id SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));

DROP TABLE IF EXISTS priority;
CREATE TABLE priority (id SERIAL PRIMARY KEY, severity INTEGER, description varchar(255));

DROP TABLE IF EXISTS users;
CREATE TABLE users (id SERIAL PRIMARY KEY, alias VARCHAR(100), email VARCHAR(100), password VARCHAR(100), active BOOLEAN);

DROP TABLE IF EXISTS ticket_status;
CREATE TABLE ticket_status (id BIGSERIAL PRIMARY KEY, name VARCHAR(255));

DROP TABLE IF EXISTS helpdesk;
CREATE TABLE helpdesk (ticket BIGSERIAL PRIMARY KEY, status INTEGER references ticket_status(id), barcode VARCHAR(255), site INTEGER references site(id) DEFAULT '1', location TEXT, requested TIMESTAMP DEFAULT current_timestamp, updated TIMESTAMP, author TEXT, contact VARCHAR(255), contact_phone VARCHAR(255), notes TEXT, section INT DEFAULT '1', problem TEXT, priority INT  DEFAULT '2', serial VARCHAR(255), tech VARCHAR(255), contact_email VARCHAR(255), technician INTEGER DEFAULT '1', submitter INTEGER, free_date DATE, free_time TIME);

DROP TABLE IF EXISTS troubleshooting;
CREATE TABLE troubleshooting(id SERIAL PRIMARY KEY, ticket_id INTEGER references helpdesk(ticket), troubleshooting TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS notes;
CREATE TABLE notes(id SERIAL PRIMARY KEY, ticket_id INTEGER references helpdesk(ticket), note TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS auth;
CREATE TABLE auth (id BIGINT, session_key TEXT, created TIMESTAMP DEFAULT current_timestamp, user_id VARCHAR(20));

DROP TABLE IF EXISTS audit;
CREATE TABLE audit (record BIGSERIAL PRIMARY KEY, status INTEGER, site INTEGER, location TEXT, updated TIMESTAMP DEFAULT current_timestamp, contact VARCHAR(255), notes TEXT, section INT, priority INT, tech VARCHAR(255), contact_email VARCHAR(255), technician INTEGER, closing_tech INTEGER, updater INTEGER, ticket INTEGER);

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
CREATE TABLE alias_aclgroup (id BIGSERIAL PRIMARY KEY, alias_id INTEGER, aclgroup_id INTEGER references aclgroup(id) ON DELETE CASCADE);

DROP TABLE IF EXISTS section_aclgroup;
CREATE TABLE section_aclgroup (id BIGSERIAL PRIMARY KEY, aclgroup_id INTEGER references aclgroup(id) ON DELETE CASCADE, section INTEGER references section(id) ON DELETE CASCADE, aclread BOOLEAN DEFAULT false, aclcreate BOOLEAN DEFAULT false, aclupdate BOOLEAN DEFAULT false, aclclose BOOLEAN DEFAULT false);




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

-- This will allow customer accounts to be created so the system can authenticate them.  The reason for this is so someone/thing can't spam the helpdesk system with tickets.  This is just one available backend for this, I also plan on add LDAP as a backend
DROP TABLE IF EXISTS customers;
CREATE TABLE customers(id SERIAL PRIMARY KEY, first VARCHAR(100), last VARCHAR(100), middle_initial VARCHAR(100), alias VARCHAR(100), password VARCHAR(100), email VARCHAR(100), active BOOLEAN, site INTEGER);

-- Adding admin user
INSERT INTO users(alias,email,password,active,sections) values('admin','admin@localhost',MD5('admin'),true,'Helpdesk');
-- this will get phased out in favor of the config file for ease of use for people who don't know a lot of SQL
INSERT INTO priority(severity,description) values(1,'Low');
INSERT INTO priority(severity,description) values(2,'Normal');
INSERT INTO priority(severity,description) values(3,'High');
INSERT INTO priority(severity,description) values(4,'Business Critical');
INSERT INTO section(name,email) values('Helpdesk','helpdesk@testcompany.com');
-- some starting ticket status
INSERT INTO ticket_status (name) values ('New');
INSERT INTO ticket_status (name) values ('In Progress');
INSERT INTO ticket_status (name) values ('Waiting Customer');
INSERT INTO ticket_status (name) values ('Waiting Vendor');
INSERT INTO ticket_status (name) values ('Waiting Other');
INSERT INTO ticket_status (name) values ('Closed');
INSERT INTO ticket_status (name) values ('Completed');
-- test data to start with 
INSERT INTO site_level(type) values ('test');
INSERT INTO site (level,name) values (1,'Test Site');

CREATE OR REPLACE FUNCTION insert_object(active_val BOOLEAN) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO object (active) values(active_val);
	SELECT INTO last_id currval('object_id_seq');

	RETURN last_id;
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

CREATE OR REPLACE FUNCTION update_object_value(value_val VARCHAR(255), value_id_val INTEGER) RETURNS INTEGER AS $$
BEGIN
	UPDATE value set value = value_val where id = value_id_val;

	RETURN 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_ticket(site_val INTEGER, status_val INTEGER, barcode_val VARCHAR(255), location_val TEXT, author_val TEXT, contact_val VARCHAR(255), contact_phone_val VARCHAR(255), troubleshot_val TEXT, section_val INTEGER, problem_val TEXT, priority_val INTEGER, serial_val VARCHAR(255), contact_email_val VARCHAR(255), tech_val INTEGER, notes_val TEXT, submitter_val INTEGER, free_date_val DATE, free_time_val TIME) RETURNS INTEGER AS $$
DECLARE
	last_id INTEGER;
BEGIN
	INSERT INTO helpdesk (status, barcode, site, location, author, contact, contact_phone, section, problem, priority, serial, contact_email, technician, notes, submitter, free_date, free_time) values (status_val, barcode_val, site_val, location_val, author_val, contact_val, contact_phone_val, section_val, problem_val, priority_val, serial_val, contact_email_val,tech_val,notes_val,submitter_val,free_date_val,free_time_val);
	SELECT INTO last_id currval('helpdesk_ticket_seq');

	INSERT INTO audit (status, site, location, contact, section, priority, contact_email, technician, notes, updater, ticket) values (status_val, site_val, location_val, contact_val, section_val, priority_val, contact_email_val, tech_val, notes_val, submitter_val, last_id);

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (ticket_id,troubleshooting) values(last_id,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (ticket_id,note) values(last_id,notes_val);
	END IF;

	RETURN last_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_ticket(ticket_number BIGINT, site_text text, location_val TEXT,  contact_val VARCHAR(255), contact_phone_val VARCHAR(255), troubleshot_val TEXT, contact_email_val VARCHAR(255), notes_val TEXT, status_val INTEGER, tech_val INTEGER, updater_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	priority_val INTEGER;
	site_val INTEGER;
	section_val INTEGER;
	last_id INTEGER;
BEGIN
	--Step 1. Translate priority, site, status, section into values from the other tables
	SELECT INTO site_val id FROM site WHERE name = site_text;
	
	-- Step 2. Update all the columns
	update helpdesk set updated = current_timestamp where ticket = ticket_number;
	update helpdesk set contact = contact_val where ticket = ticket_number;
	update helpdesk set contact_phone = contact_phone_val where ticket = ticket_number;
	update helpdesk set site = site_val where ticket = ticket_number;
	update helpdesk set location = location_val where ticket = ticket_number;
	update helpdesk set status = status_val where ticket = ticket_number;
	
	INSERT INTO audit (status, site, location, contact, section, priority, contact_email, technician, notes, updater, ticket) values (status_val, site_val, location_val, contact_val, section_val, priority_val, contact_email_val, tech_val, notes_val, updater_val, ticket_number);

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (ticket_id,troubleshooting) values(ticket_number,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (ticket_id,note) values(ticket_number,notes_val);
	END IF;
	
	last_id := 1; --this doesn't do anything and should be replaced with something related to this operation.  I am placing this here because I don't know how to make a stored procedure yet without a return val
	RETURN last_id;
END;
$$ LANGUAGE plpgsql;

-- Permissions and stuff
DROP USER helpdesk;
CREATE USER helpdesk WITH PASSWORD 'helpdesk';
GRANT SELECT, INSERT, UPDATE, DELETE ON ticket_status TO helpdesk;
GRANT SELECT, UPDATE ON ticket_status_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON site_level TO helpdesk;
GRANT SELECT, UPDATE ON site_level_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON site TO helpdesk;
GRANT SELECT, UPDATE ON site_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON status TO helpdesk;
GRANT SELECT, UPDATE ON status_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON helpdesk TO helpdesk;
GRANT SELECT, UPDATE ON helpdesk_ticket_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON priority TO helpdesk;
GRANT SELECT, UPDATE ON priority_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON section TO helpdesk;
GRANT SELECT, UPDATE ON section_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO helpdesk;
GRANT SELECT, UPDATE ON users_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON customers TO helpdesk;
GRANT SELECT, UPDATE ON customers_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON troubleshooting TO helpdesk;
GRANT SELECT, UPDATE ON troubleshooting_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO helpdesk;
GRANT SELECT, UPDATE ON notes_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON company TO helpdesk;
GRANT SELECT, UPDATE ON company_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON audit TO helpdesk;
GRANT SELECT, UPDATE ON audit_record_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON template TO helpdesk;
GRANT SELECT, UPDATE ON template_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON property TO helpdesk;
GRANT SELECT, UPDATE ON property_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON value TO helpdesk;
GRANT SELECT, UPDATE ON value_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON object TO helpdesk;
GRANT SELECT, UPDATE ON object_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON template_property TO helpdesk;
GRANT SELECT, UPDATE ON template_property_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON value_property TO helpdesk;
GRANT SELECT, UPDATE ON value_property_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON object_value TO helpdesk;
GRANT SELECT, UPDATE ON object_value_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON aclgroup TO helpdesk;
GRANT SELECT, UPDATE ON aclgroup_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON alias_aclgroup TO helpdesk;
GRANT SELECT, UPDATE ON alias_aclgroup_id_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON section_aclgroup TO helpdesk;
GRANT SELECT, UPDATE ON section_aclgroup_id_seq TO helpdesk;
