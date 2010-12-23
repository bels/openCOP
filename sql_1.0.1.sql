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

-- Default template-property associations
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'os'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'cpu'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'description'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'hard_drive'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'ram'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'username'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'password'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'role'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'server'),(select id from property where property = 'serial'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'domain_name'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'serial'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'firewall'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'serial'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'router'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'serial'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'switch'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'serial'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'printer'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'model'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'serial'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'wap'),(select id from property where property = 'description'));

INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'vendor'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'ip_address'));
INSERT INTO template_property(template_id,property_id) values((select id from template where template = 'isp'),(select id from property where property = 'description'));


