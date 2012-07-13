drop database if exists forum;
create database forum;
drop user  forum;
GRANT ALL PRIVILEGES ON forum.* TO forum@'%' IDENTIFIED BY '%mysql-forum-password%';
flush privileges;
