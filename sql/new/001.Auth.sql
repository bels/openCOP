CREATE SCHEMA IF NOT EXISTS auth AUTHORIZATION opencop_user;

CREATE TABLE auth.users (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	first TEXT,
	last TEXT,
	middle_initial TEXT,
	login_identifier TEXT UNIQUE,
	password TEXT,
	active BOOLEAN DEFAULT true,
	site INTEGER DEFAULT null
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.users TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.users
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE auth.profile_data_type(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	description TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.profile_data_type TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.profile_data_type
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE auth.profile(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
	data_type UUID REFERENCES auth.profile_data_type(id),
	content TEXT NOT NULL,
	default_primary BOOLEAN DEFAULT TRUE NOT NULL,
	active BOOLEAN DEFAULT TRUE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.profile TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.profile
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
-------------------------------------------------------------------------------------

CREATE TABLE auth.permissions (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	permission TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.permissions TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.permissions
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE auth.object(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	name TEXT NOT NULL
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.object TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.object
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE auth.user_permission (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
	permission_id UUID NOT NULL REFERENCES auth.permissions(id) ON DELETE CASCADE,
	object_id UUID NOT NULL REFERENCES auth.object(id) ON DELETE CASCADE,
	UNIQUE (user_id,permission_id,object_id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.user_permission TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.user_permission
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

-------------------------------------------------------------------------------------

CREATE TABLE auth.sessions(
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	user_id UUID NOT NULL REFERENCES auth.users(id),
	login_identifier TEXT NOT NULL,
	ip TEXT NOT NULL,
	active BOOLEAN DEFAULT true
);

GRANT SELECT, INSERT, UPDATE, DELETE ON auth.sessions TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON auth.sessions
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();