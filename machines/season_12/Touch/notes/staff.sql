- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: htb_airways
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `_htb_staff`
--

DROP TABLE IF EXISTS `_htb_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_htb_staff` (
  `id` int NOT NULL AUTO_INCREMENT,
  `employee_id` varchar(20) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `last_name` varchar(100) NOT NULL,
  `email` varchar(255) NOT NULL,
  `auth_code` varchar(64) DEFAULT NULL,
  `role` varchar(100) NOT NULL,
  `department` varchar(100) DEFAULT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `base_airport` varchar(10) DEFAULT NULL,
  `hire_date` date DEFAULT NULL,
  `phone_ext` varchar(10) DEFAULT NULL,
  `active` tinyint DEFAULT '1',
  `last_login` datetime DEFAULT NULL,
  `notes` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `employee_id` (`employee_id`)
) ENGINE=InnoDB AUTO_INCREMENT=151 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `_htb_staff`
--

LOCK TABLES `_htb_staff` WRITE;
/*!40000 ALTER TABLE `_htb_staff` DISABLE KEYS */;
INSERT INTO `_htb_staff` VALUES (1,'HTB-97248','Marcus','Mitchell','mmitchell@htbairways.htb','4601947A40E4BDCE','Cargo Supervisor','Safety & Compliance','BDG-161430','ORD','2014-12-25','4601',1,'2026-04-04 22:42:06',NULL),(2,'HTB-80469','Elena','Kovacs','ekovacs@htbairways.htb','D4E96DB85AECAFC4','First Officer','Flight Operations','BDG-545523','SFO','2024-09-25','8444',1,'2026-04-03 17:47:00',NULL),(3,'HTB-98398','David','Andersen','dandersen@htbairways.htb','255160EA80AF52CC','Senior Check-in Agent','Engineering & Maintenance','BDG-398063','HKG','2010-08-27','6730',1,'2026-04-02 12:51:00',NULL),(4,'HTB-25469','Sarah','Nakamura','snakamura@htbairways.htb','65BBA59D1B5145E7','First Officer','Revenue Management','BDG-420823','HKG','2009-05-28','8268',1,'2026-04-02 21:16:00',NULL),(5,'HTB-76155','James','Okonkwo','jokonkwo@htbairways.htb','EA42FAB8CAE50D63','Maintenance Technician','Terminal Operations','BDG-457691','CDG','2016-05-23','1023',1,NULL,NULL),(6,'HTB-38997','Priya','Bergström','pbergstrm@htbairways.htb','D531E04C42758846','Check-in Agent','Security','BDG-814602','LAX','2020-12-13','9830',1,'2026-04-04 16:41:00',NULL),(7,'HTB-66373','Thomas','Santos','tsantos@htbairways.htb','DBEA8BF35F3B93A3','Aviation Security Lead','Training & Development','BDG-807343','HKG','2020-09-22','7355',1,'2026-04-02 06:33:00',NULL),(8,'HTB-58295','Mei','Patel','mpatel@htbairways.htb','E624511D7FD0A720','Customer Service Agent','Engineering & Maintenance','BDG-677885','CDG','2016-09-26','2003',1,'2026-04-02 09:58:00',NULL),(9,'HTB-98600','Carlos','Dubois','cdubois@htbairways.htb','88123126BC55AC23','Duty Manager','In-Flight Services','BDG-109474','JFK','2020-10-20','3525',1,'2026-04-02 18:27:00',NULL),(10,'HTB-34325','Fatima','Kim','fkim@htbairways.htb','60F90262004EF01F','Gate Agent','Catering Services','BDG-723165','CDG','2009-01-02','7232',1,'2026-04-01 16:10:00',NULL),(11,'HTB-43955','Robert','Hoffmann','rhoffmann@htbairways.htb','AD59D674FEE120D4','Revenue Management Analyst','Crew Management','BDG-338886','ATL','2023-02-02','6137',1,'2026-04-04 19:26:00',NULL),(12,'HTB-45332','Anika','Torres','atorres@htbairways.htb','5E029161F6ECE1A9','Quality Assurance Inspector','Terminal Operations','BDG-663485','SIN','2016-07-08','1220',1,'2026-04-02 07:10:00',NULL),(13,'HTB-15827','William','Ivanova','wivanova@htbairways.htb','43F718B0397FFDF5','Operations Manager','Training & Development','BDG-209987','ATL','2023-12-06','8588',1,'2026-04-03 11:55:00',NULL),(14,'HTB-54598','Yuki','Yamamoto','yyamamoto@htbairways.htb','BFDD344882B28674','Operations Manager','Crew Management','BDG-779206','LAX','2014-09-01','8768',1,'2026-04-04 15:50:00',NULL),(15,'HTB-75142','Ahmed','Al-Rashid','aalrashid@htbairways.htb','B0E5D6C0675DC6DC','Security Screening Officer','Security','BDG-571717','SIN','2020-01-11','7962',1,NULL,NULL),(16,'HTB-24441','Olivia','Lindberg','olindberg@htbairways.htb','1871D8DE90E9135B','Check-in Supervisor','Cargo Operations','BDG-491066','CDG','2013-06-23','8310',1,'2026-04-04 22:32:00',NULL),(17,'HTB-89426','Sergei','Müller','smller@htbairways.htb','DFD0F7A09BFC9351','Baggage Handler','Terminal Operations','BDG-571942','LAX','2011-05-23','6866',1,'2026-04-03 12:23:00',NULL),(18,'HTB-73230','Nina','Fernandez','nfernandez@htbairways.htb','48E3CA097528E009','Ticketing Agent','Security','BDG-324086','LAX','2015-06-01','4177',1,'2026-04-02 05:28:00',NULL),(19,'HTB-12142','Patrick','Johansson','pjohansson@htbairways.htb','CC1C6384C79F8486','Safety Officer','Ground Services','BDG-792958','NRT','2025-02-16','8415',1,NULL,NULL),(20,'HTB-11937','Zara','Chen','zchen@htbairways.htb','7BF959E12104A59B','Flight Engineer','Engineering & Maintenance','BDG-618772','LAX','2025-01-06','4076',1,'2026-04-03 10:21:00',NULL),(21,'HTB-58317','Michael','McAllister','mmcallister@htbairways.htb','A653E3DEECCBDBCE','Customer Service Agent','Terminal Operations','BDG-274006','SFO','2009-04-09','7257',1,NULL,NULL),(22,'HTB-34190','Chloe','Petrov','cpetrov@htbairways.htb','9C70CBAA6540797E','Terminal Coordinator','In-Flight Services','BDG-447498','CDG','2014-01-02','9265',1,'2026-04-01 16:07:00',NULL),(23,'HTB-21796','Benjamin','Gonzalez','bgonzalez@htbairways.htb','65D6F6CED43D3C2E','Line Maintenance Supervisor','Customer Experience','BDG-149939','MIA','2011-11-11','7795',1,'2026-04-02 11:54:00',NULL),(24,'HTB-97223','Leila','Tanaka','ltanaka@htbairways.htb','6348DC443E0883A9','Line Maintenance Supervisor','Flight Operations','BDG-340077','SFO','2013-08-02','3149',1,'2026-04-02 06:37:00',NULL),(25,'HTB-31181','Andre','Ibrahim','aibrahim@htbairways.htb','B678BB6055ACE81F','Station Manager','Customer Experience','BDG-127811','CDG','2018-12-11','5643',1,'2026-04-04 05:52:00',NULL),(26,'HTB-18972','Sophie','Nielsen','snielsen@htbairways.htb','A172D8EA101681AE','Check-in Supervisor','Ground Services','BDG-362969','ATL','2019-06-20','2190',1,'2026-04-02 16:10:00',NULL),(27,'HTB-15335','Kenji','Weber','kweber@htbairways.htb','E5AEFED3F2EEA35F','First Officer','Cargo Operations','BDG-933105','AMS','2015-04-05','6144',1,'2026-04-04 05:31:00',NULL),(28,'HTB-23411','Amara','Martinez','amartinez@htbairways.htb','B53951FF8C7B63CE','Lounge Manager','Revenue Management','BDG-760222','NRT','2023-07-20','2974',1,'2026-04-01 13:08:00',NULL),(29,'HTB-35391','Luis','Suzuki','lsuzuki@htbairways.htb','7DD9286F5DC8B104','Ticketing Agent','Customer Experience','BDG-696932','ATL','2014-06-10','8722',1,'2026-04-01 05:11:00',NULL),(30,'HTB-98705','Eva','Hassan','ehassan@htbairways.htb','F83329B17B0C0E83','Customer Service Agent','Revenue Management','BDG-310986','ORD','2021-01-06','2383',1,NULL,NULL),(31,'HTB-37522','Daniel','Eriksson','deriksson@htbairways.htb','644D5E009C35E316','Safety Officer','Catering Services','BDG-131329','CDG','2021-04-21','4652',1,'2026-04-04 20:12:00',NULL),(32,'HTB-58288','Ingrid','Silva','isilva@htbairways.htb','B95FB54E61B9B4AC','Station Manager','Ground Services','BDG-880903','JFK','2020-04-28','2836',1,'2026-04-02 08:27:00',NULL);
/*!40000 ALTER TABLE `_htb_staff` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-10  2:11:58
