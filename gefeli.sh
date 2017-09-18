#!/bin/sh

#DECLARACIÓN DE VARIABLES
FILEHOST=/etc/hosts

#leer archivos de propiedades
file="./nodos.properties"

k=0
#comprueba la existencia del archivo nodos.properties
if [ -f "$file" ];

then
    echo "$file found"
. $file

#itera el array de host y escribe en el archivo hosts
for i in "${hosts[@]}";
do
    echo ${hosts[k]}  ${dns[k]} >> /etc/hosts

k=$k+1

done
else
    echo "$file not found"
fi

k=0
binMaster1 = 0
posMaster1 = 0

#itera para cada uno de los hosts la configuración y despliegue de base de datos MARIADB en cluster
while [ $k -le ${#hosts[@]} ];do
echo "comienza configuracion del host: " ${hosts[@]}
scp -"$FILEHOST" root@${hosts[$k]}:/etc/
echo "Copia del archivo " $FILEHOST "en el host: " ${hosts[$k]}
ssh root@${hosts[$k]} "sudo yum groupinstall 'Development Tools'"
echo "herramientas de desarrollo instaladas"
ssh root@${hosts[$k]} "sed 's/\SELINUX=enforcing/SELINUX=disabled/g -i ~/etc/selinux/conf'"
echo "SELINUX configurado correctamente "
ssh root@${hosts[$k]} "sudo yum -y update"
echo "yum update ejecutado"
ssh root@${hosts[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=3306/tcp"
ssh root@${hosts[$k]} "sudo firewall-cmd --reload"
echo "firewall configurado y recargado"
ssh root@${hosts[$k]} "> /etc/yum.repos.d/MariaDB.repo"
echo "archivo repo creado"
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
  
ssh root@${hosts[$k]} "yum -y install MariaDB-server MariaDB-client rsync wget"
echo "MariaDb Server y Cliente instalados"
ssh root@${hosts[$k]} "systemctl enable mariadb.service"
echo "servicio mariadb habilitado"
#ssh root@${hosts[$k]} "mysql_secure_installation"


if [  ${dns[k]} = "master1" ];
then
echo "INICIA LA CONFIGURACION DEL MASTER 1"

sleep 3

ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=10\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"

echo "archivo server.cnf modificado"

sleep 3

ssh root@${hosts[$k]} "systemctl start mariadb.service"

echo "inicia el servicio de MariaDB"

sleep 3

ssh root@${hosts[$k]} "mysql --user=root <<_EOF
CREATE USER 'reply'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'reply'@'%' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
_EOF
"
echo "Usuario reply creado"

sleep 3

ssh root@{hosts[$k]} "systemctl restart mariadb.service"
echo "Reinicio del servicio MariaDB"

sleep 2

#binlog y posición para replicación
bin=$(ssh root@${hosts[0]} 'mysql -e "show master status;" | tail -n 1')
binMaster1=$(echo $bin | awk {'print $1'})
pos=$(ssh root@${hosts[0]} "mysql -e 'show master status;' | tail -n 1")
posMaster1=$(echo $pos | awk {'print $2'})
echo "Variables POS: " $posMaster1 "y BIN: " $binMaster1

sleep 2

ssh root@{hosts[$k]} "mysqldump mysql > mysql-db.sql"

echo "Export de base de datos creado"

sleep 2

ssh root@{hosts[$k]} "rsync -Pazxvl mysql-db.sql root@{hosts[$k]}:/root/"

echo "Copiar archivo mysql_db.sql a cada uno de los hosts"

sleep 2

ssh root@{hosts[$k]} "
mysql --user=root <<_EOF
unlock tables;
stop slave;
change master to master_host= '{hosts[1]}' , master_user='reply', master_password='reply', master_log_file=binMaster1 , master_log_pos=posMaster1;
start slave;
_EOF
"
echo "Configuración del Master host usuario de glpi creado"

sleep 2

else
echo "INICIA LA CONFIGURACION DEL MASTER 2"

ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=20\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"

echo "archivo server.cnf configurado"

sleep 2

ssh root@${hosts[$k]} "systemctl start mariadb.service"

echo "MariaDB reiniciado"

sleep 2

ssh root@{hosts[$k]} "mysql < mysql-db.sql"

echo "Base de datos Importada"

sleep 2 

ssh root@{hosts[$k]} "
mysql --user=root <<_EOF
unlock tables;
stop slave;
change master to master_host= '{hosts[0]}' , master_user='reply', master_password='reply', master_log_file=binMaster1 , master_log_pos=posMaster1;
start slave;
CREATE DATABASE glpi;
CREATE USER "glpi"@"%" IDENTIFED BY "glpi";
GRANT ALL PRIVILEGES ON glpi TO "glpi"@"%";
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
_EOF
"

echo "Master host configurado"

sleep 2 

ssh root@{hosts[$k]} "glpi < glpi.sql"

echo "base de datos restaurada"

sleep 2

ssh root@{hosts[$k]} "chmod +x scriptgefeli.sh"

echo "permisos de ejecución de scriptgefeli.sh"

sleep 2

ssh root@{hosts[$k]} "./scriptgefeli.sh"

echo "ejecución de scriptgefeli.sh"

fi
let k = k + 1
done 
