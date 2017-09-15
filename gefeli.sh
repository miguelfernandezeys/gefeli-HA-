#!/bin/sh

#####MEDIA HORA PERDIDA POR LA FALTA DEL PATH DEL SHEBANG

#DECLARACIÓN DE VARIABLES
FILEHOST=/etc/hosts

# Instalar las actualizaciones del sistema

file="./nodos.properties"

if [ -f "$file" ];

then
    echo "$file found"
. $file
else
    echo "$file not found"
fi
k=0
for i in "${hosts[@]}";
do
    echo ${hosts[k]}  ${dns[k]} >> /etc/hosts

k=$k+1

done

k=0
binMaster1 = 0
posMaster1 = 0
while [ $k -le ${#hosts[@]} ];do
scp -"$FILEHOST" root@${hosts[$k]}:/etc/
ssh root@${hosts[$k]} "sudo yum groupinstall 'Development Tools'"
ssh root@${hosts[$k]} "sed 's/\SELINUX=enforcing/SELINUX=disabled/g -i ~/etc/selinux/conf'"
ssh root@${hosts[$k]} "sudo yum -y update"
ssh root@${hosts[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=3306/tcp"
ssh root@${hosts[$k]} "sudo firewall-cmd --reload"
ssh root@${hosts[$k]} "> /etc/yum.repos.d/MariaDB.repo"
  
ssh root@${hosts[$k]} 'echo "
# MariaDB 10.1 CentOS repository list - created 2017-08-04 03:32 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey = https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck = 1
" >> /etc/yum.repos.d/MariaDB.repo'
ssh root@${hosts[$k]} "cat /etc/yum.repos.d/MariaDB.repo"
  
ssh root@${hosts[$k]} "yum -y install MariaDB-server MariaDB-client rsync"
ssh root@${hosts[$k]} "systemctl enable mariadb.service"
#ssh root@${hosts[$k]} "mysql_secure_installation"

if [  ${dns[k]} = "master1" ];
then
ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=10\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"
ssh root@${hosts[$k]} "systemctl start mariadb.service"
ssh root@{hosts[$k]} "mysql -e 'CREATE USER "reply"@"%" IDENTIFIED BY "reply"; GRANT REPLICATION SLAVE ON *.* TO "reply"@"%" IDENTIFIED BY "reply"; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK;'"
ssh root@{hosts[$k]} "systemctl restart mariadb.service"
#binlog y posición para replicación
bin=$(ssh root@192.168.56.104 'mysql -e "show master status;" | tail -n 1')
binMaster1=$(echo $bin | awk {'print $1'})
#echo $bin
pos=$(ssh root@192.168.56.104 "mysql -e 'show master status;' | tail -n 1")
posMaster1=$(echo $pos | awk {'print $2'})
#echo $pos
ssh root@{hosts[$k]} "mysqldump mysql > mysql-db.sql"
ssh root@{hosts[$k]} "rsync -Pazxvl mysql-db.sql root@{hosts[$k]}:/root/"
ssh root@{hosts[$k]} "root@{hosts[$k]}:/root/"
ssh root@{hosts[$k]} "mysql -e 'unlock tables; stop slave; change master to master_host= '{hosts[1]}' , master_user='reply', master_password='reply', master_log_file= 
binMaster1 , master_log_pos=posMaster1; start slave; CREATE DATABASE glpi; CREATE USER "glpi"@"%" IDENTIFED BY "glpi"; GRANT ALL PRIVILEGES ON glpi TO "glpi"@"%" ; FLUSH PRIVILEGES; '"
ssh root@{hosts[$k]} "glpi < base_de_datos.sql"
ssh root@{hosts[$k]} "chmod +x gefeli.sh"
ssh root@{hosts[$k]} "./gefeli.sh"
else
ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=20\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"
ssh root@${hosts[$k]} "systemctl start mariadb.service"
ssh root@{hosts[$k]} "mysql < mysql-db.sql"
ssh root@{hosts[$k]} "mysql -e 'stop slave; change master to master_host= '{hosts[0]}' , master_user='reply', master_password='reply', master_log_file= 
binMaster1 , master_log_pos=posMaster1; ; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK; start slave; show slave status'"

fi

let k = k + 1

done
sleep 4

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
