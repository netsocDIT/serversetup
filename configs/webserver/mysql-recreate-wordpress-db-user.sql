drop database if exists wordpress;
create database wordpress;
drop user  wordpress;
GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@'%' IDENTIFIED BY '%mysql-wordpress-password%';
flush privileges;
