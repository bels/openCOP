CREATE SCHEMA IF NOT EXISTS ticket AUTHORIZATION opencop_user;

SET SEARCH_PATH TO ticket,public;

CREATE TABLE status (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	status TEXT NOT NULL,
	active BOOLEAN DEFAULT true
);

GRANT SELECT, INSERT, UPDATE, DELETE ON status TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON status
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE section (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	name TEXT UNIQUE,
	email TEXT,
	active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE section IS 'A section could be something like telecom, helpdesk, automation. IE. a division of logical problems';

GRANT SELECT, INSERT, UPDATE, DELETE ON section TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON section
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE technician_section(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	technician UUID REFERENCES auth.users(id),
	section UUID REFERENCES section(id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON technician_section TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON technician_section
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE priority (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	severity INTEGER NOT NULL,
	description TEXT NOT NULL,
	active BOOLEAN DEFAULT true
);

GRANT SELECT, INSERT, UPDATE, DELETE ON priority TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON priority
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
CREATE TABLE ticket (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	ticket BIGSERIAL,
	status UUID references status(id),
	barcode TEXT,
	site UUID references opencop.site(id),
	location TEXT,
	author TEXT,
	contact TEXT,
	contact_phone TEXT,
	section UUID references section(id),
	synopsis TEXT,
	problem TEXT,
	priority UUID references priority(id),
	serial TEXT,
	contact_email TEXT,
	technician UUID references auth.users(id),
	submitter UUID NOT NULL references auth.users(id),
	availability_time TIMESTAMPTZ,
	closed_by UUID references auth.users(id),
	completed_by UUID references auth.users(id),
	active BOOLEAN DEFAULT true
);

GRANT USAGE, SELECT ON SEQUENCE ticket_ticket_seq TO opencop_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ticket TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON ticket
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE troubleshooting(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	technician UUID references auth.users(id),
	ticket UUID references ticket(id),
	troubleshooting TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON troubleshooting TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON troubleshooting
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE notes(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	ticket UUID references ticket(id),
	note TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON notes TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON notes
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE reports (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	name TEXT NOT NULL UNIQUE,
	report TEXT,
	owner UUID references auth.users(id),
	description TEXT DEFAULT null
);

GRANT SELECT, INSERT, UPDATE, DELETE ON reports TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON reports
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE wo(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	name TEXT NOT NULL,
	active BOOLEAN DEFAULT true
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wo TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON wo
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
CREATE TABLE wo_template(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	wo_id UUID references wo(id) ON DELETE CASCADE,
	section_id UUID references section(id) ON DELETE CASCADE,
	requires_id UUID references wo_template(id),
	step INTEGER,
	problem TEXT DEFAULT null
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wo_template TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON wo_template
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE wo_ticket (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT current_timestamp,
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	ticket UUID REFERENCES ticket(id),
	requires UUID REFERENCES ticket(id),
	wo_id UUID references wo(id),
	step INTEGER
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wo_ticket TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON wo_ticket
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();