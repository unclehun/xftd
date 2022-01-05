CREATE USER '$c_user'@'%' IDENTIFIED BY '$c_pwd';
GRANT ALL ON *.* TO '$c_user'@'%';
CREATE USER '$c_user'@'localhost' IDENTIFIED BY '$c_pwd';
GRANT ALL ON *.* TO '$c_user'@'localhost';
CREATE USER '$c_user'@'127.0.0.1' IDENTIFIED BY '$c_pwd';
GRANT ALL ON *.* TO '$c_user'@'127.0.0.1';
flush privileges;