-- Grant access to 'user@127.0.0.1'
-- required for inter-container communication in a pod

CREATE USER IF NOT EXISTS 'qsmaster'@'localhost';

CREATE DATABASE IF NOT EXISTS qservResult;
GRANT ALL ON qservResult.* TO 'qsmaster'@'localhost';

-- Secondary index database (i.e. objectId/chunkId relation)
-- created by integration test script/loader for now
GRANT ALL ON qservMeta.* TO 'qsmaster'@'localhost';

-- CSS database
GRANT ALL ON qservCssData.* TO 'qsmaster'@'localhost';

-- Create user for external monitoring applications
CREATE USER IF NOT EXISTS 'monitor'@'localhost' IDENTIFIED BY 'CHANGEMETOO';
GRANT PROCESS ON *.* TO 'monitor'@'localhost';
