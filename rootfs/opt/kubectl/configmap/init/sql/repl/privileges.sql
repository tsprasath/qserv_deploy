CREATE DATABASE qservReplica;

set @repl_dn := 'repl-ctl.qserv';

SET @query = CONCAT('CREATE USER `qsreplica`@`', @repl_dn, '`');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @query = CONCAT('GRANT ALL ON qservReplica.* TO `qsreplica`@`', @repl_dn, '`');
PREPARE stmt FROM @query;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

CREATE USER `qsreplica`@`repl-wrk%.qserv`;
GRANT SELECT ON qservReplica.* TO `qsreplica`@`repl-wrk%.qserv`;

FLUSH PRIVILEGES;
