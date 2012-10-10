update mysql.user set password=PASSWORD('%mysql-root-password%') where user='root';
flush privileges;
