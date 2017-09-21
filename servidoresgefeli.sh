#!/bin/sh

#DECLARACIÓN DE VARIABLES
exec &> instalacionservidores.log
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
for i in "${hostsserver[@]}";
do
    echo ${hostsserver[$k]}  ${dnsserver[$k]} >> /etc/hosts

k=$k+1

done
else
    echo "$file not found"
fi

