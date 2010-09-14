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

DROP TABLE IF EXISTS site;
CREATE TABLE site (scid SERIAL PRIMARY KEY, level INTEGER references school_level(slid), name VARCHAR(255), deleted smallint);

DROP TABLE IF EXISTS purchase;
CREATE TABLE purchase (pid BIGSERIAL PRIMARY KEY, purchased timestamp, arrived timestamp, order_number varchar(255), notes text);

DROP TABLE IF EXISTS status;
CREATE TABLE status (stid SERIAL PRIMARY KEY, status VARCHAR(255));

DROP TABLE IF EXISTS section;
CREATE TABLE section (sid SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));

DROP TABLE IF EXISTS priority;
CREATE TABLE priority (prid SERIAL PRIMARY KEY, severity INTEGER, description varchar(255));

DROP TABLE IF EXISTS helpdesk;
CREATE TABLE helpdesk (ticket BIGSERIAL PRIMARY KEY, status INTEGER references ticket_status(tsid), barcode VARCHAR(255), site INTEGER references site(scid), location TEXT, requested TIMESTAMP DEFAULT current_timestamp, updated TIMESTAMP, author TEXT, contact VARCHAR(255), contact_phone VARCHAR(255), troubleshot TEXT, notes TEXT, section INT references section(sid), problem TEXT, priority INT references priority(prid), serial VARCHAR(255), tech VARCHAR(255), contact_email VARCHAR(255), free VARCHAR(255));

DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (invid BIGSERIAL PRIMARY KEY, ccps BIGINT, hardware_type INTEGER references hardware_type(hwid), site INTEGER references site(scid), serial VARCHAR(255), model BIGINT references equipment(eid), mac varchar(32), ip varchar(255), name varchar(255), room varchar(255), software TEXT, assigned_to varchar(255), grantid BIGINT references grants(gid), status INTEGER references status(stid), installer varchar(255), port varchar(127), notes TEXT, os BIGINT references os(osid), office BIGINT references office(offid), hdd varchar(255), speed varchar(127), ram BIGINT, po BIGINT references purchase(pid), dept varchar(255), cost BIGINT references cost(cid), updated timestamp, deployed timestamp);

DROP TABLE IF EXISTS replacement;
CREATE TABLE replacement (original BIGINT references inventory(invid), replacement BIGINT references inventory(invid), replaced_on timestamp);

DROP TABLE IF EXISTS auth;
CREATE TABLE auth (sid BIGINT, session_key TEXT, created TIMESTAMP DEFAULT current_timestamp, uid VARCHAR(20));

DROP TABLE IF EXISTS users;
CREATE TABLE users (id SERIAL, alias VARCHAR, email TEXT, password TEXT, active BOOLEAN);
INSERT INTO users(alias,email,password,active) values('admin','admin@localhost',MD5('admin'),true);

CREATE OR REPLACE FUNCTION insert_ticket(site text, status text, barcode VARCHAR(255), location TEXT, author TEXT, contact VARCHAR(255), contact_phone VARCHAR(255), troubleshot TEXT, section VARCHAR(255), problem TEXT, priority TEXT, serial VARCHAR(255), contact_email VARCHAR(255), free VARCHAR(255)) RETURNS INTEGER AS'
DECLARE
	priority_val INTEGER;
	site_val INTEGER;
	status_val INTEGER;
	section_val INTEGER;
	last_id INTEGER;
BEGIN
	--Step 1. Translate priority, site, status, section into values from the other tables
	priority_val = SELECT prid FROM priority WHERE description = priority;
	site_val = SELECT scid FROM site WHERE name = site;
	status_val = SELECT stid FROM ticket_status WHERE name = status;
	section_val = SELECT sid FROM section WHERE name = section;
	
	-- Step 2. Insert the ticket with the translated values
	INSERT INTO helpdesk (status, barcode, site, location, author, contact, contact_phone, troubleshot, section, problem, priority, serial, contact_email) values (status_val, barcode, site_val, location, author, contact, contact_phone, troubleshot, section_val, problem, priority_val, serial, contact_email);
	SELECT currval(''helpdesk_ticket_seq'') INTO last_id;
	
	RETURN last_id;
END;
' LANGUAGE plpgsql;

-- Permissions and stuff
CREATE USER helpdesk WITH PASSWORD 'helpdesk';
GRANT SELECT, INSERT, UPDATE, DELETE ON cost TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON cost_cid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON vendor TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON vendor_vid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON hardware_type TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON hardware_type_hwid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON os TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON os_osid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON office TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON office_offid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON equipment TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON equipment_eid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON grants TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON grants_gid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON ticket_status TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON ticket_status_stid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON school_level TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON school_level_slid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON site TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON site_scid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON purchase TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON purchase_pid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON status TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON status_stid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON helpdesk TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON helpdesk_ticket_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON inventory_invid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON priority TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON priority_prid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON replacement TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON section TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON section_sid_seq TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON auth TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON users TO helpdesk;
GRANT SELECT, INSERT, UPDATE, DELETE ON users_id_seq TO helpdesk;