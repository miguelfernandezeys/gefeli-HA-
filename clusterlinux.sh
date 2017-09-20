#!/bin/sh
# redirect stdout/stderr to a file
exec &> logfile1.log

#leer archivos de propiedades
file="./nodos.properties"

k=0

while [ $k -lt ${#hosts[@]} ];do
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

let k = k + 1


echo "clave asignada"

done

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

k=0

while [ $k -lt ${#hosts[@]} ];do

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
let k = k + 1
done

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
