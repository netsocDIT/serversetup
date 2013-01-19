drop database if exists wiki;
create database wiki;
drop user  wiki;
GRANT ALL PRIVILEGES ON wiki.* TO wiki@'%' IDENTIFIED BY '%mysql-wiki-password%';
flush privileges;
