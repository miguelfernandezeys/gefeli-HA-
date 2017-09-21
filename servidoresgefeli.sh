#!/bin/sh

#DECLARACIÓN DE VARIABLES
exec &> instalacionservidores.log
FILEHOST=/etc/hosts

#leer archivos de propiedades
file="./nodosserver.properties"

k=0
#comprueba la existencia del archivo nodos.properties
if [ -f "$file" ];

then
    echo "$file found"
. $file

#itera el array de host y escribe en el archivo hosts
for i in "${hostsserver[@]}";
do
    echo ${hostsserver[$k]}  ${dnsserver[$k]} >> /etc/hosts

k=$k+1

done
else
    echo "$file not found"
fi

echo "Instalación y configuración de glpi 9.1.3"
k=0
while [ $k -lt ${#hostsserver[@]} ];do
echo "comienza configuracion del host: " ${hostsserver[$k]}
ssh root@${hostsserver[$k]} "sudo firewall-cmd --zone=public --permanent --add-port=80/tcp"
ssh root@${hostsserver[$k]} "sudo firewall-cmd --reload"
echo "firewall modificado y recargado"
ssh root@${hostsserver[$k]} "yum install httpd php php-mysql php-gd php-mbstring php-ldap wget unzip"
echo "Instalación de paquetes necesarios finalizada"
ssh root@${hostsserver[$k]} "systemctl enable httpd"
ssh root@${hostsserver[$k]} "systemctl start httpd"
echo "servidor httpd habilitado e iniciado"
ssh root@${hostsserver[$k]} "wget https://github.com/glpi-project/glpi/releases/download/9.1.3/glpi-9.1.3.tgz"
echo "glpi 9.1.3 descargado"
ssh root@${hostsserver[$k]} "tar -xzvf glpi-9.1.3.tgz"
echo "glpi 9.1.3 descomprimido"
ssh root@${hostsserver[$k]} "mv glpi /var/www/html"
ssh root@${hostsserver[$k]} "chown -R apache:apache /var/www/html/glpi/"
ssh root@${hostsserver[$k]} "chmod -R 777 /var/www/html/glpi/"
ssh root@${hosts[$k]} "sed -e '119d' -i /etc/httpd/conf/httpd.conf"
ssh root@${hosts[$k]} "sed -e '164d' -i /etc/httpd/conf/httpd.conf"
echo "archivo server.cnf modificado"
variable1="/var/www/html/glpi"
ssh root@${hosts[$k]} "sed '119i\DocumentRoot "variable1" \n ' -i /etc/httpd/conf/httpd.conf"
ssh root@${hosts[$k]} "sed '164i\    DirectoryIndex /glpi/ \n ' -i /etc/httpd/conf/httpd.conf"

echo "Para continuar el proceso ingrese a la dirección ip  ${hostsserver[$k]}, actualice y al concluir oprima cualquier tecla"

read $var1

ssh root@${hosts[$k]} "rm -r /var/www/html/glpi"

echo "Borrado de paquete glpi"

ssh root@${hosts[$k]} "unzip gefeli.zip"
ssh root@${hosts[$k]} "mv glpi /var/www/html"

ssh root@${hostsserver[$k]} "chown -R apache:apache /var/www/html/glpi/"

ssh root@${hostsserver[$k]} "chmod -R 777 /var/www/html/glpi/"

ssh root@${hosts[$k]} "mv /var/www/html/glpi/config/config_db.php /var/www/html/glpi/config/config_db.php.bk "

ssh root@${hosts[$k]} "> /var/www/html/glpi/config/config_db.php"

ssh root@${hosts[$k]} "echo '
<?php
 class DB extends DBmysql {

 hola $dbhost     = '"${direcciondinamica}"';

 hola $dbuser     = 'glpi';

 hola $dbpassword = 'glpi';

 hola $dbdefault  = 'glpi';

}
' >> /var/www/html/glpi/config/config_db.php"

echo "fin de script :o"
done
