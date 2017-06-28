CREATE OR REPLACE FUNCTION auth.register(first_name_val TEXT, last_name_val TEXT, password_val TEXT, email_val TEXT) RETURNS TABLE(id UUID, status INTEGER, message TEXT) AS $$
DECLARE
    user_id_val UUID;
BEGIN
	
	INSERT INTO auth.users (first,last,password,login_identifier) VALUES (first_name_val,last_name_val,crypt(password_val,gen_salt('bf',8)),email_val) RETURNING auth.users.id INTO user_id_val;
	IF FOUND THEN
		INSERT INTO auth.profile (user_id,content,data_type) VALUES (user_id_val,email_val,(SELECT auth.profile_data_type.id FROM auth.profile_data_type WHERE description = 'email' LIMIT 1));
		IF FOUND THEN
			RETURN QUERY SELECT user_id_val,1,'User created successfully'::TEXT;
		ELSE
			RETURN QUERY SELECT user_id_val,-2,'Could not insert profile data'::TEXT;
		END IF;
	ELSE
		RETURN QUERY SELECT user_id_val,-1,'Failed to create user'::TEXT;
	END IF;
	RETURN;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.authenticate (login_identifier_val TEXT, pswhash_val TEXT) RETURNS TABLE (message TEXT, status INTEGER) AS $$
BEGIN
    IF (SELECT count(*) FROM auth.users WHERE lower(login_identifier) = lower(login_identifier_val) AND password = crypt(pswhash_val,password) AND active = true) > 0 THEN
        RETURN QUERY 
        	SELECT 'Login Success'::TEXT,1;
    ELSE
        IF (SELECT count(*) FROM auth.users WHERE lower(login_identifier) = lower(login_identifier)) = 1 THEN
    		IF (SELECT count(*) FROM auth.users WHERE lower(login_identifier) = lower(login_identifier) AND active = false) = 1 THEN
    			RETURN QUERY
        			SELECT 'Account not active'::TEXT,-3;
    		ELSE
    			RETURN QUERY
        			SELECT 'Bad password'::TEXT,-1;
    		END IF; 
    	ELSE
    		RETURN QUERY
        		SELECT 'Account not found'::TEXT,-2;
    	END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.has_permission(user_id_val UUID, permission_val TEXT, object_id_val UUID,on_behalf_id UUID DEFAULT NULL) RETURNS BOOLEAN AS $$
DECLARE
	perm_count INTEGER;
BEGIN
	SELECT 
		count(*) INTO perm_count 
	FROM 
		auth.user_permission up
	WHERE
		up.user_id = user_id_val
	AND
		up.object_id = object_id_val
	AND
		up.permission_id = (SELECT id FROM auth.permissions WHERE permission = permission_val);
	IF perm_count = 0 THEN
		SELECT
			count(*) INTO perm_count
		FROM
			auth.on_behalf_permissions obp
		JOIN
			auth.account_associations aa
		ON
			obp.association = aa.id
		WHERE
			aa.primary_account = user_id_val
		AND
			aa.secondary_account = on_behalf_id
		AND
			obp.object = object_id_val
		AND
			obp.permission = (SELECT id FROM auth.permissions WHERE permission = permission_val);
	END IF;
	IF perm_count > 0 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.has_permission(user_id_val UUID, permission_val TEXT, object_val TEXT,on_behalf_id UUID DEFAULT NULL) RETURNS BOOLEAN AS $$
DECLARE
	perm_count INTEGER;
	object_id_val UUID;
BEGIN
	SELECT id INTO object_id_val FROM auth.object WHERE name = object_val;
	SELECT 
		count(*) INTO perm_count 
	FROM 
		auth.user_permission up
	WHERE
		up.user_id = user_id_val
	AND
		up.object_id = object_id_val
	AND
		up.permission_id = (SELECT id FROM auth.permissions WHERE permission = permission_val);
	IF perm_count = 0 THEN
		SELECT
			count(*) INTO perm_count
		FROM
			auth.on_behalf_permissions obp
		JOIN
			auth.account_associations aa
		ON
			obp.association = aa.id
		WHERE
			aa.primary_account = user_id_val
		AND
			aa.secondary_account = on_behalf_id
		AND
			obp.object = object_id_val
		AND
			obp.permission = object_id_val;
	END IF;
	IF perm_count > 0 THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.give_permission(user_id_val UUID, permission_val TEXT, object_id_val UUID) RETURNS BOOLEAN AS $$
DECLARE
	permission_id_val UUID;
BEGIN
	SELECT id INTO permission_id_val FROM auth.permissions WHERE permission = permission_val;
	INSERT INTO auth.user_permission (user_id,permission_id,object_id) VALUES (user_id_val,permission_id_val,object_id_val);
	IF FOUND THEN
		RETURN true;
	ELSE
		RETURN false;
	END IF;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.update_profile (user_id_val UUID, data_type_val TEXT, data_val TEXT) RETURNS BOOLEAN AS $$
DECLARE
	data_type_id_val UUID;
BEGIN
	SELECT id INTO data_type_id_val FROM auth.profile_data_type WHERE description = data_type_val;
	--TODO eventually we'll need to detect what to do with the old data and handle
	--TODO also need to handle arrays of data
	INSERT INTO auth.profile(user_id,data_type,content) VALUES (user_id_val,data_type_id_val,data_val);
	
	IF FOUND THEN
		RETURN true;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$ LANGUAGE plpgsql;

----------------------------------------------------------------

CREATE OR REPLACE FUNCTION auth.does_user_exist(login_identifier_val TEXT) RETURNS TABLE(user_exists BOOLEAN) AS $$
BEGIN 
		RETURN QUERY SELECT 
			CASE WHEN EXISTS(
				SELECT 1 FROM auth.users u WHERE u.login_identifier = login_identifier_val
			) THEN
				true
			ELSE
				false
			END;
END;
$$ LANGUAGE plpgsql;