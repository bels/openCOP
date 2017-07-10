CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION opencop_user;

set search_path to audit,public;

CREATE TABLE audit.traffic(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT current_timestamp,
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

GRANT ALL ON traffic TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON traffic
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE auth(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	client_ip TEXT,
	login_identifier TEXT,
	login_successful BOOLEAN
);

GRANT ALL ON auth TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
CREATE TABLE ticket (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT current_timestamp,
	update_type TEXT,
	status UUID references ticket.status(id),
	notes TEXT,
	updater UUID REFERENCES auth.users(id),
	ticket UUID REFERENCES ticket.ticket(id) ON DELETE CASCADE,
	time_worked INTERVAL
);

GRANT ALL ON ticket TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON ticket
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();