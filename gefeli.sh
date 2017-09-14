#!bin/sh
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

while [ $k -le ${#hosts[@]} ];do
  scp -"$FILEHOST" root@${hosts[$k]}:/etc/
  ssh root@${hosts[$k]} "yum -y update | firewall-cmd --zone=public --permanent --add-port=3306/tcp | firewall-cmd --reload | > /etc/yum.repos.d/MariaDB.repo"
  ssh root@${hosts[$k]} 'echo "
# MariaDB 10.0 CentOS repository list - created 2017-08-04 03:32 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
" >> /etc/yum.repos.d/MariaDB.repo'
  ssh root@${hosts[$k]} "cat /etc/yum.repos.d/MariaDB.repo"
  
  ssh root@${hosts[$k]} "yum -y install MariaDB-server MariaDB-client rsync"
  ssh root@${hosts[$k]} "systemctl enable mysql"
  
  #Configuración de demonio
  ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=10\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"
  ssh root@${hosts[$k]} "systemctl start mysql"
  
  #binlog y posición para replicación 
  ssh root@${hosts[$k]} "bin=$(mysql -e 'show master status;' | tail -n 1 | awk {'print $1'})"
  ssh root@${hosts[$k]} "pos=$(mysql -e "show master status;" | tail -n 1 | awk {'print $2'})"
done

sleep 4

#sleep 1



echo $bin $pos

#Exportar base de datos

mysqldump mysql > mysql-db.sql

rsync -Pazxvl mysql-db.sql root@192.168.56.102:/root/
#

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
