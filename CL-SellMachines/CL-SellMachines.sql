CREATE TABLE IF NOT EXISTS `cl_sellmachines` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `location` mediumtext DEFAULT NULL,
  `money` int(11) DEFAULT 0,
  `name` mediumtext DEFAULT NULL,
  `items` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
