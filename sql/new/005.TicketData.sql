set search_path to ticket,public;

INSERT INTO section(name,email) values('helpdesk','helpdesk@email.address');

INSERT INTO status (status) values ('New');
INSERT INTO status (status) values ('In Progress');
INSERT INTO status (status) values ('Waiting Customer');
INSERT INTO status (status) values ('Waiting Vendor');
INSERT INTO status (status) values ('Waiting Other');
INSERT INTO status (status) values ('Closed');
INSERT INTO status (status) values ('Completed');

INSERT INTO priority(severity,description) values(1,'Low');
INSERT INTO priority(severity,description) values(2,'Normal');
INSERT INTO priority(severity,description) values(3,'High');
INSERT INTO priority(severity,description) values(4,'Business Critical');