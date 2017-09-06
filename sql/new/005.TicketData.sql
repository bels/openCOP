set search_path to ticket,public;

INSERT INTO section(name,email) values('Helpdesk','helpdesk@email.address');

INSERT INTO status (status) values ('New');
INSERT INTO status (status) values ('In Progress');
INSERT INTO status (status) values ('On-Site Scheduled');
INSERT INTO status (status) values ('Waiting Customer');
INSERT INTO status (status) values ('Waiting Vendor');
INSERT INTO status (status) values ('Waiting Other');
INSERT INTO status (status) values ('Closed');
INSERT INTO status (status) values ('Completed');

INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'New'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'In Progress'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'On-Site Scheduled'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'Waiting Customer'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'Waiting Vendor'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'Waiting Other'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Technician'),(select id from status where status = 'Closed'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Quality Assurance'),(select id from status where status = 'Completed'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'New'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'In Progress'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'On-Site Scheduled'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'Waiting Customer'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'Waiting Vendor'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'Waiting Other'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'Closed'));
INSERT INTO account_available_statuses(account_type,status) values((select id from auth.account_types where name = 'Admin'),(select id from status where status = 'Completed'));

INSERT INTO priority(severity,description) values(1,'Low');
INSERT INTO priority(severity,description) values(2,'Normal');
INSERT INTO priority(severity,description) values(3,'High');
INSERT INTO priority(severity,description) values(4,'Business Critical');

INSERT INTO technician_section(technician,section) VALUES ((select id from auth.users where first = 'Admin'),(select id from section where name = 'Helpdesk'));

INSERT INTO reports(name, report, description) VALUES ('Tickets Received','tickets_received','How many tickets the helpdesk has received over a certain period of time');
INSERT INTO reports(name, report, description) VALUES ('Tickets Per User', 'tickets_received_per_user','Returns the tickets put in over a certain time frame per user');
INSERT INTO reports(name, report, description) VALUES ('Tickets Closed','tickets_closed','Returns the tickets closed by company and technician');
INSERT INTO reports(name, report, description) VALUES ('Ticket Open Times','ticket_time','Returns tickets age and synopsis');
INSERT INTO reports(name, report, description) VALUES ('Billable Tickets','billable_tickets','Returns tickets that are marked billable in a certain timeframe');