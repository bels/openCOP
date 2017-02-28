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