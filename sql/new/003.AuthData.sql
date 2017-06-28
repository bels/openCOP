set search_path to auth,public;
INSERT INTO profile_data_type (description) VALUES ('email');
INSERT INTO profile_data_type (description) VALUES ('mobile phone');
INSERT INTO profile_data_type (description) VALUES ('home phone');
INSERT INTO profile_data_type (description) VALUES ('work phone');

perform select register('Admin','User','password','admin@example.com'); --TODO This needs to be change per install to the correct domain