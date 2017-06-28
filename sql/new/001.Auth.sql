CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION opencop_user;

SET SEARCH_PATH TO auth,public;

CREATE TABLE users (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	first TEXT,
	last TEXT,
	middle_initial TEXT,
	login_identifier TEXT UNIQUE,
	password TEXT,
	active BOOLEAN DEFAULT true,
	site UUID REFERENCES opencop.company(id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON users TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON users
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE profile_data_type(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	description TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON profile_data_type TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON profile_data_type
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE profile(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID REFERENCES users(id) ON DELETE CASCADE,
	data_type UUID REFERENCES profile_data_type(id),
	content TEXT NOT NULL,
	default_primary BOOLEAN DEFAULT TRUE NOT NULL,
	active BOOLEAN DEFAULT TRUE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON profile TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON profile
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
-------------------------------------------------------------------------------------

CREATE TABLE permissions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	permission TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON permissions TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON permissions
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE object(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	name TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON object TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON object
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE user_permission (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
	permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
	object_id UUID NOT NULL REFERENCES object(id) ON DELETE CASCADE,
	UNIQUE (user_id,permission_id,object_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON user_permission TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON user_permission
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE sessions(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID NOT NULL REFERENCES users(id),
	login_identifier TEXT NOT NULL,
	ip TEXT NOT NULL,
	active BOOLEAN DEFAULT true
);

GRANT SELECT, INSERT, UPDATE, DELETE ON sessions TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON sessions
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();