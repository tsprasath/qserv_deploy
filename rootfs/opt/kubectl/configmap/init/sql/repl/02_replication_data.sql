SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 ;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 ;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL' ;

USE qservReplica;

-----------------------------------------------------------
-- Preload configuration parameters for testing purposes --
-----------------------------------------------------------

-- Common parameters of all types of servers

INSERT INTO `config` VALUES ('common', 'request_buf_size_bytes',     '131072');
INSERT INTO `config` VALUES ('common', 'request_retry_interval_sec', '5');

-- Controller-specific parameters

INSERT INTO `config` VALUES ('controller', 'num_threads',            '16');
INSERT INTO `config` VALUES ('controller', 'http_server_port',    '25080');
INSERT INTO `config` VALUES ('controller', 'http_server_threads',    '16');
INSERT INTO `config` VALUES ('controller', 'request_timeout_sec', '57600');   -- 16 hours
INSERT INTO `config` VALUES ('controller', 'job_timeout_sec',     '57600');   -- 16 hours
INSERT INTO `config` VALUES ('controller', 'job_heartbeat_sec',       '0');   -- temporarily disabled

-- Database service-specific parameters

INSERT INTO `config` VALUES ('database', 'services_pool_size', '32');

-- Connection parameters for the Qserv Management Services

INSERT INTO `config` VALUES ('xrootd', 'auto_notify',         '1');
INSERT INTO `config` VALUES ('xrootd', 'host',                'localhost');
INSERT INTO `config` VALUES ('xrootd', 'port',                '1094');
INSERT INTO `config` VALUES ('xrootd', 'request_timeout_sec', '600');

-- Default parameters for all workers unless overwritten in worker-specific
-- tables

INSERT INTO `config` VALUES ('worker', 'technology',                 'FS');
INSERT INTO `config` VALUES ('worker', 'svc_port',                   '25000');
INSERT INTO `config` VALUES ('worker', 'fs_port',                    '25001');
INSERT INTO `config` VALUES ('worker', 'num_svc_processing_threads', '16');
INSERT INTO `config` VALUES ('worker', 'num_fs_processing_threads',  '32');       -- double compared to the previous one to allow more elasticity
INSERT INTO `config` VALUES ('worker', 'fs_buf_size_bytes',          '4194304');  -- 4 MB
INSERT INTO `config` VALUES ('worker', 'data_dir',                   '/qserv/data/mysql');

-- Preload parameters for runnig all services on the same host

INSERT INTO `config_worker` VALUES ('db01', 1, 0, 'lsst-qserv-db01',  NULL, 'lsst-qserv-db01',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db02', 1, 0, 'lsst-qserv-db02',  NULL, 'lsst-qserv-db02',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db03', 1, 0, 'lsst-qserv-db03',  NULL, 'lsst-qserv-db03',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db04', 1, 0, 'lsst-qserv-db04',  NULL, 'lsst-qserv-db04',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db05', 1, 0, 'lsst-qserv-db05',  NULL, 'lsst-qserv-db05',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db06', 1, 0, 'lsst-qserv-db06',  NULL, 'lsst-qserv-db06',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db07', 1, 0, 'lsst-qserv-db07',  NULL, 'lsst-qserv-db07',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db08', 1, 0, 'lsst-qserv-db08',  NULL, 'lsst-qserv-db08',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db09', 1, 0, 'lsst-qserv-db09',  NULL, 'lsst-qserv-db09',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db10', 1, 0, 'lsst-qserv-db10',  NULL, 'lsst-qserv-db10',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db11', 1, 0, 'lsst-qserv-db11',  NULL, 'lsst-qserv-db11',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db12', 1, 0, 'lsst-qserv-db12',  NULL, 'lsst-qserv-db12',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db13', 1, 0, 'lsst-qserv-db13',  NULL, 'lsst-qserv-db13',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db14', 1, 0, 'lsst-qserv-db14',  NULL, 'lsst-qserv-db14',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db15', 1, 0, 'lsst-qserv-db15',  NULL, 'lsst-qserv-db15',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db16', 1, 0, 'lsst-qserv-db16',  NULL, 'lsst-qserv-db16',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db17', 1, 0, 'lsst-qserv-db17',  NULL, 'lsst-qserv-db17',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db18', 1, 0, 'lsst-qserv-db18',  NULL, 'lsst-qserv-db18',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db19', 1, 0, 'lsst-qserv-db19',  NULL, 'lsst-qserv-db19',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db20', 1, 0, 'lsst-qserv-db20',  NULL, 'lsst-qserv-db20',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db21', 1, 0, 'lsst-qserv-db21',  NULL, 'lsst-qserv-db21',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db22', 1, 0, 'lsst-qserv-db22',  NULL, 'lsst-qserv-db22',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db23', 1, 0, 'lsst-qserv-db23',  NULL, 'lsst-qserv-db23',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db24', 1, 0, 'lsst-qserv-db24',  NULL, 'lsst-qserv-db24',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db25', 1, 0, 'lsst-qserv-db25',  NULL, 'lsst-qserv-db25',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db26', 1, 0, 'lsst-qserv-db26',  NULL, 'lsst-qserv-db26',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db27', 1, 0, 'lsst-qserv-db27',  NULL, 'lsst-qserv-db27',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db28', 1, 0, 'lsst-qserv-db28',  NULL, 'lsst-qserv-db28',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db29', 1, 0, 'lsst-qserv-db29',  NULL, 'lsst-qserv-db29',  NULL, NULL);
INSERT INTO `config_worker` VALUES ('db30', 1, 0, 'lsst-qserv-db30',  NULL, 'lsst-qserv-db30',  NULL, NULL);


SET SQL_MODE=@OLD_SQL_MODE ;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS ;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS ;
