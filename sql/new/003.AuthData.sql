set search_path to auth,public;
INSERT INTO profile_data_type (description) VALUES ('email');
INSERT INTO profile_data_type (description) VALUES ('mobile phone');
INSERT INTO profile_data_type (description) VALUES ('home phone');
INSERT INTO profile_data_type (description) VALUES ('work phone');
INSERT INTO profile_data_type (description) VALUES ('account_type');

--admin permissions
insert into permissions(permission) values('admin');
insert into object(name) values ('opencop system');

select * from register('Admin','User','password','admin@example.com'); --TODO This needs to be change per install to the correct domain
select * from update_profile((select id from users where login_identifier='admin@example.com'),'account_type','technician');

insert into user_permission(user_id,permission_id,object_id) values((select id from users where login_identifier = 'admin@example.com'),(select id from permissions where permission = 'admin'),(select id from object where name = 'opencop system'));