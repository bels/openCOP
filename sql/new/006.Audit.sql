CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION opencop_user;

set search_path to audit,public;

CREATE TABLE audit.traffic(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	client_ip TEXT,
	uri TEXT,
	login_identifier TEXT,
	method TEXT,
	post_data TEXT,
	referring_page TEXT,
	protocol TEXT,
	host TEXT,
	user_agent TEXT,
	host_port TEXT,
	client_port TEXT
);

GRANT ALL ON audit.traffic TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON audit.traffic
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE audit.auth(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	client_ip TEXT,
	login_identifier TEXT,
	login_successful BOOLEAN
);

GRANT ALL ON audit.auth TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON audit.auth
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
CREATE TABLE ticket (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	status INTEGER,
	site INTEGER,
	location TEXT,
	updated TIMESTAMP DEFAULT current_timestamp,
	contact_name Text,
	notes TEXT,
	section UUID REFERENCES ticket.section(id),
	priority UUID REFERENCES ticket.priority(id),
	contact_email TEXT,
	technician UUID REFERENCES auth.users(id),
	updater UUID REFERENCES auth.users(id),
	ticket UUID REFERENCES ticket.ticket(id),
	time_worked INTERVAL
);