GRANT ALL PRIVILEGES ON netsoc.* TO netsoc@'%' IDENTIFIED BY '%mysql-wordpress-password%';
drop database if exists netsoc;
create database netsoc;
