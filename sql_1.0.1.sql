ALTER TABLE auth ADD COLUMN last_active TIMESTAMP DEFAULT now();

CREATE OR REPLACE FUNCTION reset_logout(id_val INTEGER) RETURNS INTEGER AS $$
BEGIN
	update auth set last_active = now() where id = id_val;
	RETURN id_val;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cleanup_auth() RETURNS INTEGER AS $$
BEGIN
	DELETE FROM auth WHERE (now() - last_active) > '01:00:00';
	RETURN '1';
END;
$$ LANGUAGE plpgsql;

