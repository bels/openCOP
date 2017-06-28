CREATE EXTENSION "pgcrypto";
CREATE EXTENSION "uuid-ossp";

CREATE OR REPLACE FUNCTION public.integrity_enforcement() RETURNS TRIGGER AS $$
BEGIN
	NEW.id = OLD.id;
	NEW.genesis = OLD.genesis;
	NEW.modified = current_timestamp;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


---- Auth Dependencies ----

CREATE SCHEMA IF NOT EXISTS opencop AUTHORIZATION opencop_user;

SET SEARCH_PATH TO opencop,public;

CREATE TABLE site_level (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	type TEXT UNIQUE,
	active BOOLEAN DEFAULT TRUE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON site_level TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON site_level
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE company (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	name TEXT,
	active BOOLEAN DEFAULT TRUE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON company TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON company
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();

CREATE TABLE site (
	id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
	genesis TIMESTAMPTZ DEFAULT now(),
	modified TIMESTAMPTZ DEFAULT now(),
	level UUID references site_level(id) ON DELETE CASCADE,
	name TEXT,
	active BOOLEAN DEFAULT TRUE,
	company_id UUID references company(id) ON DELETE CASCADE
);

GRANT SELECT, INSERT, UPDATE, DELETE ON site TO opencop_user;
CREATE TRIGGER integrity_enforcement BEFORE UPDATE ON site
	FOR EACH ROW EXECUTE PROCEDURE public.integrity_enforcement();
	
----- Init Data

insert into site_level(type) values('Headquarters');
insert into site_level(type) values('Branch Office');
insert into site_level(type) values('Satelite Office');