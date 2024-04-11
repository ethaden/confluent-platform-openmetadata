#!/bin/bash

# Please provide password for mariadb root user in MARIADB_ROOT_PASSWORD

mariadb -u root -p${MARIADB_ROOT_PASSWORD} -h mariadb <<EOF
CREATE DATABASE IF NOT EXISTS demo;
use demo;
CREATE TABLE IF NOT EXISTS Persons (
    PersonID int AUTO_INCREMENT,
    LastName varchar(255) NOT NULL,
    FirstName varchar(255) NOT NULL,
    Address varchar(255),
    City varchar(255),
    PRIMARY KEY(PersonID)
);
CREATE USER IF NOT EXISTS '${MARIADB_CONNECT_USER}'@'%' IDENTIFIED BY '${MARIADB_CONNECT_PASSWORD}';
GRANT ALL PRIVILEGES ON demo.Persons TO '${MARIADB_CONNECT_USER}'@'%';
GRANT SELECT, RELOAD, SHOW DATABASES, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${MARIADB_CONNECT_USER}'@'%';
commit;
EOF
