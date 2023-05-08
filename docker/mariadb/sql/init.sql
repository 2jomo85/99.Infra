CREATE DATABASE testdb;
CREATE user 'user' identified BY 'password';
GRANT ALL PRIVILEGES ON testdb.* TO 'user'@'%';