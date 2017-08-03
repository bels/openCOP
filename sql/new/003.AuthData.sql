set search_path to auth,public;
INSERT INTO account_types(name) VALUES('Admin');
INSERT INTO account_types(name) VALUES('Client');
INSERT INTO account_types(name) VALUES('Technician');
INSERT INTO account_types(name) VALUES('Quality Assurance');


INSERT INTO profile_data_type (description) VALUES ('email');
INSERT INTO profile_data_type (description) VALUES ('mobile phone');
INSERT INTO profile_data_type (description) VALUES ('home phone');
INSERT INTO profile_data_type (description) VALUES ('work phone');

--admin permissions
insert into permissions(permission) values('admin');
insert into object(name) values ('opencop system');

select * from register('Admin','User','password','admin@example.com'); --TODO This needs to be change per install to the correct domain

update users set account_type = (select id from account_types where name = 'Admin');

insert into user_permission(user_id,permission_id,object_id) values((select id from users where login_identifier = 'admin@example.com'),(select id from permissions where permission = 'admin'),(select id from object where name = 'opencop system'));