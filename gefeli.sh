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
ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=10\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"
echo "archivo server.cnf modificado"
ssh root@${hosts[$k]} "systemctl start mariadb.service"
echo "inicia el servicio de MariaDB"
ssh root@{hosts[$k]} "mysql -e 'CREATE USER "reply"@"%" IDENTIFIED BY "reply"; GRANT REPLICATION SLAVE ON *.* TO "reply"@"%" IDENTIFIED BY "reply"; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK;'"
echo "Usuario reply creado"
ssh root@{hosts[$k]} "systemctl restart mariadb.service"
echo "Reinicio del servicio MariaDB"
#binlog y posición para replicación
bin=$(ssh root@${hosts[0]} 'mysql -e "show master status;" | tail -n 1')
binMaster1=$(echo $bin | awk {'print $1'})
pos=$(ssh root@${hosts[0]} "mysql -e 'show master status;' | tail -n 1")
posMaster1=$(echo $pos | awk {'print $2'})
echo "Variables POS: " $posMaster1 "y BIN: " $binMaster1
ssh root@{hosts[$k]} "mysqldump mysql > mysql-db.sql"
echo "Export de base de datos creado"
ssh root@{hosts[$k]} "rsync -Pazxvl mysql-db.sql root@{hosts[$k]}:/root/"
echo "Copiar archivo mysql_db.sql a cada uno de los hosts"
ssh root@{hosts[$k]} "root@{hosts[$k]}:/root/"
ssh root@{hosts[$k]} "mysql -e 'unlock tables; stop slave; change master to master_host= '{hosts[1]}' , master_user='reply', master_password='reply', master_log_file= 
binMaster1 , master_log_pos=posMaster1; start slave; CREATE DATABASE glpi; CREATE USER "glpi"@"%" IDENTIFED BY "glpi"; GRANT ALL PRIVILEGES ON glpi TO "glpi"@"%" ; FLUSH PRIVILEGES; '"
echo "Configuración del Master host usuario de glpi creado"
ssh root@{hosts[$k]} "glpi < glpi.sql"
echo "base de datos restaurada"
ssh root@{hosts[$k]} "chmod +x scriptgefeli.sh"
echo "permisos de ejecución de scriptgefeli.sh"
ssh root@{hosts[$k]} "./scriptgefeli.sh"
echo "ejecución de scriptgefeli.sh"
else
echo "INICIA LA CONFIGURACION DEL MASTER 2"
ssh root@${hosts[$k]} "sed 's/\[mysqld]/[mysqld]\nserver-id=20\nlog-bin=mysql-bin/g' -i /etc/my.cnf.d/server.cnf"
echo "archivo server.cnf configurado"
ssh root@${hosts[$k]} "systemctl start mariadb.service"
echo "MariaDB reiniciado"
ssh root@{hosts[$k]} "mysql < mysql-db.sql"
echo "Base de datos Importada"
ssh root@{hosts[$k]} "mysql -e 'stop slave; change master to master_host= '{hosts[0]}' , master_user='reply', master_password='reply', master_log_file= 
binMaster1 , master_log_pos=posMaster1; ; FLUSH PRIVILEGES; FLUSH TABLES WITH READ LOCK; start slave; show slave status'"
echo "Master host configurado"

fi

############################## CONFIGURACIÓN DE CLUSTER ############################
ssh root@${hosts[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=5404/tcp"
ssh root@${hosts[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=5405/tcp"
ssh root@${hosts[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=2224/udp"
ssh root@${hosts[$k]} "sudo firewall-cmd --reload"
echo "firewall configurado y recargado"
ssh root@${hosts[$k]} "yum install corosync pcs pacemaker"
echo "herramientas de cluster instaladas"
ssh root@${hosts[$k]} "systemctl enable pcsd.servicer"
echo "pcsd habilitado"
ssh root@${hosts[$k]} "systemctl enable pacemaker.service"
echo "pacemaker habilitado"
ssh root@${hosts[$k]} "systemctl enable corosync.service"
echo "corosync habilitado"
ssh root@${hosts[$k]} "systemctl start pcsd.service"
echo "pcsd iniciado"
ssh root@${hosts[$k]} "pcs cluster setup --local --name gefeliDBCluster master1 master2"
echo "Nodos agregados al cluster"
ssh root@${hosts[$k]} "systemctl start pacemaker.service"
echo "pacemaker iniciado"
ssh root@${hosts[$k]} "systemctl start corosync.service"
echo "corosync iniciado"
ssh root@${hosts[$k]} "passwd hacluster"
echo "clave asignada"
ssh root@${hosts[$k]} "pcs cluster auth master1 master2"
echo "Nodos autorizados"
ssh root@${hosts[$k]} "pcs cluster start --all"
echo "Cluster iniciado"
ssh root@${hosts[$k]} "pcs status cluster"
echo "Verificación de cluster"
ssh root@${hosts[$k]} "pcs status nodes"
echo "Verificación de nodos"
ssh root@${hosts[$k]} "pcs status corosync"
echo "Verificación del servicio corosync"
ssh root@${hosts[$k]} "pcs property set stonith-enabled=false"
echo "Propiedad stonith desactivada"
ssh root@${hosts[$k]} "wget https://downloads.mariadb.com/MaxScale/2.1.6/rhel/7/x86_64/maxscale-2.1.6-1.rhel.7.x86_64.rpm"
echo "MaxScale descargado"
ssh root@${hosts[$k]} "rpm -i maxscale-2.1.6-1.rhel.7.x86_64.rpm"
echo "Paquete MaxScale instalado"
ssh root@${hosts[$k]} "systemctl enable maxscale.service"
echo "MaxScale habilitado"

ssh root@${hosts[$k]} "mv /etc/maxscale.cnf /etc/maxscale.cnf.bck"
echo "Respaldo del archivo de configurado de MaxScale creado"
ssh root@${hosts[$k]} "> /etc/maxscale.cnf"
echo "Nuevo archivo de configuración MaxScale creado"
ssh root@${hosts[$k]} 'echo "
# MaxScale documentation on GitHub:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Documentation-Contents.md

# Global parameters
#
# Complete list of configuration options:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Getting-Started/Configuration-Guide.md

[maxscale]
threads=2

# Server definitions
#
# Set the address of the server to the network
# address of a MySQL server.
#

[server1]
type=server
address=${hosts[0]}
port=3306
protocol=MySQLBackend

[server2]
type=server
address=${hosts[1]}
port=3306
protocol=MySQLBackend

# Monitor for the servers
#
# This will keep MaxScale aware of the state of the servers.
# MySQL Monitor documentation:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Monitors/MySQL-Monitor.md

[MySQL Monitor]
type=monitor
module=mysqlmon
servers=server1
user=glpi	
passwd=glpi
monitor_interval=10000

# Service definitions
#
# Service Definition for a read-only service and
# a read/write splitting service.
#

# ReadConnRoute documentation:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Routers/ReadConnRoute.md

[Read-Only Service]
type=service
router=readconnroute
servers=server2
user=glpi	
passwd=glpi
router_options=slave

# ReadWriteSplit documentation:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Routers/ReadWriteSplit.md

[Read-Write Service]
type=service
router=readwritesplit
servers=server1,server2
user=glpi	
passwd=glpi
max_slave_connections=100%

# This service enables the use of the MaxAdmin interface
# MaxScale administration guide:
# https://github.com/mariadb-corporation/MaxScale/blob/2.1/Documentation/Reference/MaxAdmin.md

[MaxAdmin Service]
type=service
router=cli

# Listener definitions for the services
#
# These listeners represent the ports the
# services will listen on.
#

[Read-Only Listener]
type=listener
service=Read-Only Service
protocol=MySQLClient
port=4008

[Read-Write Listener]
type=listener
service=Read-Write Service
protocol=MySQLClient
port=4006

[MaxAdmin Listener]
type=listener
service=MaxAdmin Service
protocol=maxscaled
socket=default
" >> /etc/maxscale.cnf'
echo "Archivo de configuración MaxScale configurado"

ssh root@${hosts[$k]} "systemctl start maxscale.service"
echo "MaxScale iniciado"
ssh root@${hosts[$k]} "sudo pcs resource create clusterip ocf:heartbeat:IPaddr2 ip=$dynamic_ip cidr_netmask=24 op monitor interval=20s" 
echo "Dirección dinámica asiganada al cluster"
ssh root@${hosts[$k]} "sudo pcs resource create maxscale systemd:maxscale op monitor interval=1s "
echo "Recurso de MaxScale creado"
ssh root@${hosts[$k]} "sudo pcs resource clone maxscale"
echo "Recurso de MaxScale clonado"
ssh root@${hosts[$k]} "pcs resource meta clusterip migración-threshold = 1 failure-timeout = 60s resource-stickiness = 100
pcs meta maxscale-clone migration-threshold = 1 fallo-timeout = 60s resource-stickiness = 100"
echo "Recursos fallidos configurados"
ssh root@${hosts[$k]} "sudo pcs constraint colocation agregar clusterip con maxscale-clone INFINITY"
echo "Restricciones VIP configurados"
let k = k + 1

done

