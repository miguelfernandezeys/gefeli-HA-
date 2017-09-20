#!/bin/sh
mysql --user=root <<_EOF
use glpi;
ALTER TABLE glpi_slas ADD familia VARCHAR(40) AFTER id;
ALTER TABLE glpi_slas ADD Horario VARCHAR(15) AFTER Familia;
ALTER TABLE glpi_slas ADD recurso VARCHAR(100) AFTER Horario;
ALTER TABLE glpi_slas ADD Nitcliente VARCHAR(40) AFTER recurso;
ALTER TABLE glpi_slas ADD Telcliente VARCHAR(40) AFTER Nitcliente;
ALTER TABLE glpi_slas ADD condiciones VARCHAR(255) AFTER Telcliente;
ALTER TABLE glpi_slas ADD propietario VARCHAR(100) AFTER condiciones;
ALTER TABLE glpi_slas ADD proveedores VARCHAR(100) AFTER propietario;
ALTER TABLE glpi_slas ADD cambiosyexc VARCHAR(100) AFTER proveedores;
ALTER TABLE glpi_slas ADD version DATETIME AFTER cambiosyexc;
ALTER TABLE glpi_slas ADD fechaversion DATETIME AFTER version;
ALTER TABLE glpi_slas ADD revision DATETIME AFTER fechaversion;
ALTER TABLE glpi_slas ADD fecharevision DATETIME AFTER revision;
ALTER TABLE glpi_slas ADD descripcion VARCHAR(255) AFTER fecharevision;
## modificacion de tablas creadas de incidentes, problemas y conocimiento
ALTER TABLE glpi_tickets MODIFY content VARCHAR(255);
ALTER TABLE glpi_problems MODIFY content VARCHAR(255);
ALTER TABLE glpi_knowbaseitems MODIFY answer VARCHAR(1024);
_EOF
