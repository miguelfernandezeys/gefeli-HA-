#!/bin/sh
SQL_HOST=localhost;

SQL_USUARIO=root;

SQL_PASSWORD=milmig1023951065;

SQL_DATABASE=glpi;
#### Ingreso de sentencias mysql para gefeli

sleep 4

SQL_ARGS="-h $SQL_HOST -u $SQL_USUARIO -p$SQL_PASSWORD -D $SQL_DATABASE -s -e"

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `familia` VARCHAR(40) AFTER `id`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `Horario` VARCHAR(15) AFTER `Familia`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `recurso` VARCHAR(100) AFTER `Horario`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `Nitcliente` VARCHAR(40) AFTER `recurso`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `Telcliente` VARCHAR(40) AFTER `Nitcliente`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `condiciones` VARCHAR(255) AFTER `Telcliente`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `propietario` VARCHAR(100) AFTER `condiciones`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `proveedores` VARCHAR(100) AFTER `propietario`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `cambiosyexc` VARCHAR(100) AFTER `proveedores`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `version` DATETIME AFTER `cambiosyexc`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `fechaversion` DATETIME AFTER `version`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `revision` DATETIME AFTER `fechaversion`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `fecharevision` DATETIME AFTER `revision`;'

mysql $SQL_ARGS 'ALTER TABLE `glpi_slas` ADD `descripcion` VARCHAR(255) AFTER `fecharevision`;'

## modificacion de tablas creadas de incidentes, problemas y conocimiento

mysql $SQL_ARGS 'ALTER TABLE `glpi_tickets` MODIFY `content` VARCHAR(255);'

mysql $SQL_ARGS 'ALTER TABLE `glpi_problems` MODIFY `content` VARCHAR(255);'

mysql $SQL_ARGS 'ALTER TABLE `glpi_knowbaseitems` MODIFY `answer` VARCHAR(1024);'




