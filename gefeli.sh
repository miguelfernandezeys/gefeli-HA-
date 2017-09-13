#!bin/sh
# Instalar las actualizaciones del sistema

yum -y update

#Instalacion de repo MariaDB 10.0
> /etc/yum.repos.d/MariaDB.repo

echo "
# MariaDB 10.0 CentOS repository list - created 2017-08-04 03:32 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
" >> /etc/yum.repos.d/MariaDB.repo

cat /etc/yum.repos.d/MariaDB.repo

sleep 4

yum -y install MariaDB-server MariaDB-client rsync

systemctl enable mysql

#Configuración de demonio

sed 's/\[mysqld]/[mysqld]\nserver-id=10\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf

systemctl start mysql

#mysql_secure_installation configuración y creación de usuario de replicación
mysql --user=root <<_EOF
UPDATE mysql.user SET Password=PASSWORD("$SQL_PASSWORD") WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE USER 'reply'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'reply'@'%' IDENTIFIED BY 'password';
FLUSH TABLES WITH READ LOCK;
FLUSH PRIVILEGES;
_EOF

sleep 1

#binlog y posición para replicación 

bin=$(mysql -u root -p1234567 -e 'show master status;' | tail -n 1 | awk {'print $1'})
pos=$(mysql -u root -p1234567 -e "show master status;" | tail -n 1 | awk {'print $2'})

echo $bin $pos

