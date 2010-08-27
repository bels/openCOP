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
CREATE TABLE equpiment(eid BIGSERIAL PRIMARY KEY, vendor BIGINT references vendor(vid), type BIGINT references hardware_type(hwid), model VARCHAR(255), description TEXT, software TEXT, warranty TEXT, warranty_date TIMESTAMP, hdd varchar(255), cost BIGINT, speed VARCHAR(127), ram BIGINT, os BIGINT references os(osid), office BIGINT references office(offid));

DROP TABLE IF EXISTS grants;
CREATE TABLE grants (gid BIGSERIAL PRIMARY KEY, code VARCHAR(255), notes TEXT);

DROP TABLE IF EXISTS ticket_status;
CREATE TABLE ticket_status (tsid SERIAL PRIMARY KEY, name VARCHAR(255));

DROP TABLE IF EXISTS school_level;
CREATE TABLE school_level (slid SERIAL PRIMARY KEY, type VARCHAR(255));

DROP TABLE IF EXISTS school;
CREATE TABLE school (scid SERIAL PRIMARY KEY, level INTEGER references school_level(slid), name VARCHAR(255), deleted TINYINT);

DROP TABLE IF EXISTS purchase;
CREATE TABLE purchase (prid BIGSERIAL PRIMARY KEY, purchased timestamp, arrived timestamp, order_number varchar(255), notes text);

DROP TABLE IF EXISTS status;
CREATE TABLE status (stid SERIAL PRIMARY KEY, status VARCHAR(255));

DROP TABLE IF EXISTS helpdesk;
CREATE TABLE helpdesk (ticket BIGSERIAL PRIMARY KEY, status INTEGER references ticket_status(tsid), barcode VARCHAR(255), school INTEGER references school(scid), serial VARCHAR(255), model BIGINT references equipment(eid), mac VARCHAR(32), ip VARCHAR(255),  name VARCHAR(255), room VARCHAR(255), software TEXT, assigned_to VARCHAR(255), grantid VARCHAR(255) references grants(gid), status INTEGER references status(stid), installer VARCHAR(255), port VARCHAR(255), notes TEXT, os BIGINT references os(osid), office BIGINT references office(offid), hdd VARCHAR(255), speed  VARCHAR(127), ram BIGINT, po BIGINT references purchase(pid), dept VARCHAR(255), cost BIGINT references cost(cid), updated timestamp,deployed TIMESTAMP);

DROP TABLE IF EXISTS inventory;
CREATE TABLE inventory (invid BIGSERIAL PRIMARY KEY, ccps BIGINT, hardware_type INTEGER references hardware_type(hwid), school INTEGER references school(scid), serial VARCHAR(255), model BIGINT references equipment(eid), mac varchar(32), ip varchar(255), name varchar(255), room varchar(255), software TEXT, assigned_to varchar(255), grantid varchar(255) references grants(gid), status INTEGER references status(stid), installer varchar(255), port varchar(127), notes TEXT, os BIGINT references os(osid), office BIGINT references office(offid), hdd varchar(255), speed varchar(127), ram BIGINT, po BIGINT references purchase(pid), dept varchar(255), cost BIGINT references cost(cid), updated timestamp, deployed timestamp);

DROP TABLE IF EXISTS priority;
CREATE TABLE priority (prid SERIAL PRIMARY KEY, severity INTEGER, description varchar(255));

DROP TABLE IF EXISTS replacement;
CREATE TABLE replacement (original BIGINT references inventory(invid), replacement BIGINT references inventory(invid), replaced_on timestamp);

DROP TABLE IF EXISTS section;
CREATE TABLE section (sid SERIAL PRIMARY KEY, name VARCHAR(255), email VARCHAR(255));
