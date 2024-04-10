#!/bin/bash

# Please provide password for mariadb root user in MARIADB_ROOT_PASSWORD

mariadb -u root -p${MARIADB_ROOT_PASSWORD} -h mariadb <<EOF
CREATE DATABASE IF NOT EXISTS demo;
use demo;
CREATE TABLE IF NOT EXISTS Persons (
    PersonID int PRIMARY KEY,
    LastName varchar(255),
    FirstName varchar(255),
    Address varchar(255),
    City varchar(255)
);
CREATE USER IF NOT EXISTS '${MARIADB_CONNECT_USER}'@'%' IDENTIFIED BY '${MARIADB_CONNECT_PASSWORD}';
GRANT ALL PRIVILEGES ON demo.Persons TO '${MARIADB_CONNECT_USER}'@'%';
commit;
EOF
