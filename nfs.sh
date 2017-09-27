#!/bin/sh
####################################script configuración nfs########################################
# redirect stdout/stderr to a file
exec &> nfs.log
#leer archivos de propiedades
file="./nodosserver.properties"
# Comprueba la existencia del archivo nodosserver.properties
if [ -f "$file" ];
then
    echo "$file found"
. $file
else
    echo "$file not found"
fi
###################################Configuración server nfs########################################
#Crear carpeta para compartir y asignar permisos de lectura y escritura 

ssh root@${balanceador[0]} "mkdir -p /var/documentos"
ssh root@${balanceador[0]} "chmod 777 /var/documentos"
echo "carpeta a compartir creada"
#Instalar servidor nfs
ssh root@${balanceador[0]} "apt-get install nfs-kernel-server nfs-common -y"
echo "paquetes de nfs server instalados"
#Mofificar permisos de acceso a carpeta por parte de los clientes
ssh root@${balanceador[0]} "echo /var/documentos   ${hostserver[0]}'(rw,sync,no_root_squash,no_all_squash)' >> /etc/exports"
ssh root@${balanceador[0]} "echo /var/documentos   ${hostserver[1]}'(rw,sync,no_root_squash,no_all_squash)' >> /etc/exports"
ssh root@${balanceador[0]} "echo portmap: ALL  >> /etc/hosts.allow"
ssh root@${balanceador[0]} "echo nfs: ALL >> /etc/hosts.allow"
echo "Servidor nfs configurado"
ssh root@${balanceador[0]} "systemctl restart nfs-kernel-server"
echo "servicio nfs reiniciado"
#################################Configuración de clientes########################################
k=0
while [ $k -lt ${#hostserver[@]} ];
do

echo "Inicia la configuración de cliente ${#hostserver[@]}"

ssh root@${hostserver[$k]} "yum -y install nfs-utils"

echo "paquetes nfs instalados"

ssh root@${hostserver[$k]} "firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload"

echo "Firewall configurado y recargado"

ssh root@${hostserver[$k]} "mkdir -p /mnt/nfs/home"

echo "Carpeta nfs creada"

ssh root@${hostserver[$k]} "systemctl enable rpcbind nfs-server nfs-lock nfs-idmap"
ssh root@${hostserver[$k]} "systemctl start rpcbind nfs-server nfs-lock nfs-idmap"

echo "servicio nfs habilitado e iniciado"

ssh root@${hostserver[$k]} "mount -t nfs ${balanceador[0]}':/var/documentos /mnt/nfs/home/'"

echo "Montaje de carpeta compartida entre servidor y cliente"

ssh root@${hostserver[$k]} "echo ${balanceador[0]}':/var/documentos    /mnt/nfs/home   nfs defaults 0 0' >> /etc/fstab"

let k=k+1
done

echo "Fin del script :o"

####################################Fin de script####################################
