-- This will remove any data in the database.  I would not recommend using this to recreate tables that got "messed up".  This file should only be used to do an initial creation of the database or to wipe everything and start over.

DROP TABLE IF EXISTS cost;
CREATE TABLE cost (cid BIGSERIAL PRIMARY KEY, cost INTEGER, name varchar(255));

DROP TABLE IF EXISTS vendor;
CREATE TABLE vendor (vid BIGSERIAL PRIMARY KEY, name varchar(255) NOT NULL, contact_info TEXT);

DROP TABLE IF EXISTS hardware_type;
CREATE TABLE hardware_type (hwid BIGSERIAL PRIMARY KEY, name TEXT);

DROP TABLE IF EXISTS os;
CREATE TABLE os (osid BIGSERIAL PRIMARY KEY, vendor BIGINT references vendor(vid), line VARCHAR(255), version VARCHAR(255), descr VARCHAR(255));

DROP TABLE IF EXISTS office;
CREATE TABLE office (offid BIGSERIAL PRIMARY KEY, vendor BIGINT references vendor(vid), line VARCHAR(255), version VARCHAR(255), descr VARCHAR(255));

DROP TABLE IF EXISTS equipment;
CREATE TABLE equipment(eid BIGSERIAL PRIMARY KEY, vendor BIGINT references vendor(vid), type BIGINT references hardware_type(hwid), model VARCHAR(255), description TEXT, software TEXT, warranty TEXT, warranty_date TIMESTAMP, hdd varchar(255), cost BIGINT, speed VARCHAR(127), ram BIGINT, os BIGINT references os(osid), office BIGINT references office(offid));

DROP TABLE IF EXISTS grants;
CREATE TABLE grants (gid BIGSERIAL PRIMARY KEY, code VARCHAR(255), notes TEXT);

DROP TABLE IF EXISTS ticket_status;
CREATE TABLE ticket_status (tsid SERIAL PRIMARY KEY, name VARCHAR(255));

DROP TABLE IF EXISTS school_level;
CREATE TABLE school_level (slid SERIAL PRIMARY KEY, type VARCHAR(255));

DROP TABLE IF EXISTS company;
CREATE TABLE company (cpid SERIAL PRIMARY KEY, name VARCHAR(255), hidden BOOLEAN);

DROP TABLE IF EXISTS site;
CREATE TABLE site (scid SERIAL PRIMARY KEY, level INTEGER references school_level(slid), name VARCHAR(255), deleted smallint, cpid INTEGER references company(cpid));

DROP TABLE IF EXISTS purchase;
CREATE TABLE purchase (pid BIGSERIAL PRIMARY KEY, purchased timestamp, arrived timestamp, order_number varchar(255), notes text);

DROP TABLE IF EXISTS status;
CREATE TABLE status (stid SERIAL PRIMARY KEY, status VARCHAR(255));

DROP TABLE IF EXISTS section;
CREATE TABLE section (sid SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));

DROP TABLE IF EXISTS priority;
CREATE TABLE priority (prid SERIAL PRIMARY KEY, severity INTEGER, description varchar(255));

DROP TABLE IF EXISTS users;
CREATE TABLE users (uid SERIAL PRIMARY KEY, alias VARCHAR(100), email VARCHAR(100), password VARCHAR(100), active BOOLEAN,sections VARCHAR(255));

DROP TABLE IF EXISTS helpdesk;
CREATE TABLE helpdesk (ticket BIGSERIAL PRIMARY KEY, status INTEGER references ticket_status(tsid), barcode VARCHAR(255), site INTEGER references site(scid), location TEXT, requested TIMESTAMP DEFAULT current_timestamp, updated TIMESTAMP, author TEXT, contact VARCHAR(255), contact_phone VARCHAR(255), notes TEXT, section INT references section(sid), problem TEXT, priority INT references priority(prid), serial VARCHAR(255), tech VARCHAR(255), contact_email VARCHAR(255), free VARCHAR(255), technician INTEGER references users(uid), submitter INTEGER);

DROP TABLE IF EXISTS troubelshooting;
CREATE TABLE troubleshooting(tid SERIAL PRIMARY KEY, tkid INTEGER references helpdesk(ticket), troubleshooting TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS notes;
CREATE TABLE notes(nid SERIAL PRIMARY KEY, tkid INTEGER references helpdesk(ticket), note TEXT, performed TIMESTAMP DEFAULT current_timestamp);

DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (invid BIGSERIAL PRIMARY KEY, ccps BIGINT, hardware_type INTEGER references hardware_type(hwid), site INTEGER references site(scid), serial VARCHAR(255), model BIGINT references equipment(eid), mac varchar(32), ip varchar(255), name varchar(255), room varchar(255), software TEXT, assigned_to varchar(255), grantid BIGINT references grants(gid), status INTEGER references status(stid), installer varchar(255), port varchar(127), notes TEXT, os BIGINT references os(osid), office BIGINT references office(offid), hdd varchar(255), speed varchar(127), ram BIGINT, po BIGINT references purchase(pid), dept varchar(255), cost BIGINT references cost(cid), updated timestamp, deployed timestamp);

DROP TABLE IF EXISTS replacement;
CREATE TABLE replacement (original BIGINT references inventory(invid), replacement BIGINT references inventory(invid), replaced_on timestamp);

DROP TABLE IF EXISTS auth;
CREATE TABLE auth (sid BIGINT, session_key TEXT, created TIMESTAMP DEFAULT current_timestamp, uid VARCHAR(20));

DROP TABLE IF EXISTS audit;
CREATE TABLE audit (record BIGSERIAL PRIMARY KEY, status INTEGER references ticket_status(tsid), site INTEGER references site(scid), location TEXT, updated TIMESTAMP DEFAULT current_timestamp, contact VARCHAR(255), notes TEXT, section INT references section(sid), priority INT references priority(prid), tech VARCHAR(255), contact_email VARCHAR(255), technician INTEGER references users(uid), closing_tech INTEGER references users(uid), free VARCHAR(255), updater INTEGER, ticket INTEGER references helpdesk(ticket));

DROP TABLE IF EXISTS template CASCADE;
DROP TABLE IF EXISTS property CASCADE; 
DROP TABLE IF EXISTS value CASCADE;
DROP TABLE IF EXISTS object CASCADE;
DROP TABLE IF EXISTS template_property;
DROP TABLE IF EXISTS value_property;
DROP TABLE IF EXISTS object_value;
DROP TABLE IF EXISTS object_type;
DROP TABLE IF EXISTS object_company;

CREATE TABLE template (tid BIGSERIAL PRIMARY KEY, template VARCHAR(255), UNIQUE (template));

CREATE TABLE property (pid BIGSERIAL PRIMARY KEY, property VARCHAR(255), UNIQUE (property));

CREATE TABLE value (vid BIGSERIAL PRIMARY KEY, value VARCHAR(255));

CREATE TABLE object (oid BIGSERIAL PRIMARY KEY, active BOOLEAN DEFAULT true);

CREATE TABLE template_property (tpid BIGSERIAL PRIMARY KEY, template_id INTEGER references template(tid) ON DELETE CASCADE, property_id INTEGER references property(pid) ON DELETE CASCADE);

CREATE TABLE value_property (pvid BIGSERIAL PRIMARY KEY, property_id INTEGER references property(pid) ON DELETE CASCADE, value_id INTEGER references value(vid) ON DELETE CASCADE);

CREATE TABLE object_value (ovid BIGSERIAL PRIMARY KEY, object_id INTEGER references object(oid) ON DELETE CASCADE, value_id INTEGER references value(vid) ON DELETE CASCADE);

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
CREATE TABLE customers(cid SERIAL PRIMARY KEY, first VARCHAR(100), last VARCHAR(100), middle_initial VARCHAR(100), alias VARCHAR(100), password VARCHAR(100), email VARCHAR(100), active BOOLEAN, site INTEGER references site(scid));

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
INSERT INTO school_level(type) values ('test');
INSERT INTO site (level,name) values (1,'Test Site');

CREATE OR REPLACE FUNCTION insert_object(active_val BOOLEAN) RETURNS INTEGER AS $$
DECLARE
	last_oid INTEGER;
BEGIN
	INSERT INTO object (active) values(active_val);
	SELECT INTO last_oid currval('object_oid_seq');

	RETURN last_oid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_object_value(value_val VARCHAR(255), property_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	last_vid INTEGER;
	last_oid INTEGER;
BEGIN
	INSERT INTO value (value) values(value_val);

	SELECT INTO last_vid currval('value_vid_seq');
	SELECT INTO last_oid currval('object_oid_seq');

	INSERT INTO value_property (property_id,value_id) values(property_val, last_vid);
	INSERT INTO object_value (object_id,value_id) values(last_oid, last_vid);

	RETURN last_vid;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_ticket(site_text text, status_val INTEGER, barcode_val VARCHAR(255), location_val TEXT, author_val TEXT, contact_val VARCHAR(255), contact_phone_val VARCHAR(255), troubleshot_val TEXT, section_text VARCHAR(255), problem_val TEXT, priority_text TEXT, serial_val VARCHAR(255), contact_email_val VARCHAR(255), free_val VARCHAR(255), tech_text VARCHAR(255), notes_val TEXT, submitter_val INTEGER) RETURNS INTEGER AS $$
DECLARE
	priority_val INTEGER;
	site_val INTEGER;
	section_val INTEGER;
	last_id INTEGER;
	tech_val INTEGER;
BEGIN
	--Step 1. Translate priority, site, status, section into values from the other tables
	SELECT INTO priority_val severity FROM priority WHERE description = priority_text;
	SELECT INTO site_val scid FROM site WHERE name = site_text;
	SELECT INTO section_val sid FROM section WHERE name = section_text;
	SELECT INTO tech_val uid FROM users WHERE alias = tech_text;
	
	-- Step 2. Insert the ticket with the translated values
		
	INSERT INTO helpdesk (status, barcode, site, location, author, contact, contact_phone, section, problem, priority, serial, contact_email, technician,notes,submitter) values (status_val, barcode_val, site_val, location_val, author_val, contact_val, contact_phone_val, section_val, problem_val, priority_val, serial_val, contact_email_val,tech_val,notes_val,submitter_val);
	SELECT INTO last_id currval('helpdesk_ticket_seq');

	INSERT INTO audit (status, site, location, contact, section, priority, contact_email, technician, notes, updater, ticket) values (status_val, site_val, location_val, contact_val, section_val, priority_val, contact_email_val, tech_val, notes_val, submitter_val, last_id);

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (tkid,troubleshooting) values(last_id,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (tkid,note) values(last_id,notes_val);
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
	SELECT INTO site_val scid FROM site WHERE name = site_text;
	
	-- Step 2. Update all the columns
	update helpdesk set updated = current_timestamp where ticket = ticket_number;
	update helpdesk set contact = contact_val where ticket = ticket_number;
	update helpdesk set contact_phone = contact_phone_val where ticket = ticket_number;
	update helpdesk set site = site_val where ticket = ticket_number;
	update helpdesk set location = location_val where ticket = ticket_number;
	update helpdesk set status = status_val where ticket = ticket_number;
	
	INSERT INTO audit (status, site, location, contact, section, priority, contact_email, technician, notes, updater, ticket) values (status_val, site_val, location_val, contact_val, section_val, priority_val, contact_email_val, tech_val, notes_val, updater_val, ticket_number);

	IF troubleshot_val NOT LIKE '' THEN
		insert into troubleshooting (tkid,troubleshooting) values(ticket_number,troubleshot_val);
	END IF;
	
	IF notes_val NOT LIKE '' THEN
		insert into notes (tkid,note) values(ticket_number,notes_val);
	END IF;
	
	last_id := 1; --this doesn't do anything and should be replaced with something related to this operation.  I am placing this here because I don't know how to make a stored procedure yet without a return val
	RETURN last_id;
END;
$$ LANGUAGE plpgsql;

-- Permissions and stuff
DROP USER helpdesk;
CREATE USER helpdesk WITH PASSWORD 'helpdesk';
GRANT SELECT, INSERT, UPDATE, DELETE ON cost TO helpdesk;
GRANT SELECT, UPDATE ON cost_cid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON vendor TO helpdesk;
GRANT SELECT, UPDATE ON vendor_vid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON hardware_type TO helpdesk;
GRANT SELECT, UPDATE ON hardware_type_hwid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON os TO helpdesk;
GRANT SELECT, UPDATE ON os_osid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON office TO helpdesk;
GRANT SELECT, UPDATE ON office_offid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON equipment TO helpdesk;
GRANT SELECT, UPDATE ON equipment_eid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON grants TO helpdesk;
GRANT SELECT, UPDATE ON grants_gid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON ticket_status TO helpdesk;
GRANT SELECT, UPDATE ON ticket_status_tsid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON school_level TO helpdesk;
GRANT SELECT, UPDATE ON school_level_slid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON site TO helpdesk;
GRANT SELECT, UPDATE ON site_scid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON purchase TO helpdesk;
GRANT SELECT, UPDATE ON purchase_pid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON status TO helpdesk;
GRANT SELECT, UPDATE ON status_stid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON helpdesk TO helpdesk;
GRANT SELECT, UPDATE ON helpdesk_ticket_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory TO helpdesk;
GRANT SELECT, UPDATE ON inventory_invid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON priority TO helpdesk;
GRANT SELECT, UPDATE ON priority_prid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON replacement TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON section TO helpdesk;
GRANT SELECT, UPDATE ON section_sid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO helpdesk;
GRANT SELECT, UPDATE ON users_uid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON customers TO helpdesk;
GRANT SELECT, UPDATE ON customers_cid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON troubleshooting TO helpdesk;
GRANT SELECT, UPDATE ON troubleshooting_tid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO helpdesk;
GRANT SELECT, UPDATE ON notes_nid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON company TO helpdesk;
GRANT SELECT, UPDATE ON company_cpid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON audit TO helpdesk;
GRANT SELECT, UPDATE ON audit_record_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON template TO helpdesk;
GRANT SELECT, UPDATE ON template_tid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON property TO helpdesk;
GRANT SELECT, UPDATE ON property_pid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON value TO helpdesk;
GRANT SELECT, UPDATE ON value_vid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON object TO helpdesk;
GRANT SELECT, UPDATE ON object_oid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON template_property TO helpdesk;
GRANT SELECT, UPDATE ON template_property_tpid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON value_property TO helpdesk;
GRANT SELECT, UPDATE ON value_property_pvid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON object_value TO helpdesk;
GRANT SELECT, UPDATE ON object_value_ovid_seq TO helpdesk;
