-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Jun 19, 2026 at 09:39 PM
-- Server version: 9.1.0
-- PHP Version: 8.3.14

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `examsgbd`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `archiver_travailleur`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `archiver_travailleur` (IN `p_id_travailleur` INT, IN `p_date_fin` DATE)   BEGIN
	-- Delete email && password
    UPDATE travailleur
    SET email = null,
    password = null
    WHERE id_travailleur = p_id_travailleur;
      
    -- Fermer toutes les appartenances d'équipe actives
    UPDATE travailleur_equipe
    SET date_fin = p_date_fin
    WHERE id_travailleur = p_id_travailleur
      AND date_fin IS NULL;

    -- Fermer le contrat actif
    UPDATE type_contrat
    SET date_fin = p_date_fin
    WHERE id_travailleur = p_id_travailleur
      AND date_fin IS NULL;
END$$

DROP PROCEDURE IF EXISTS `calculer_et_inserer_paques`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `calculer_et_inserer_paques` (IN `p_annee` INT)   BEGIN
    -- Variables pour l'algorithme de Meeus/Jones/Butcher
    DECLARE a INT;
    DECLARE b INT;
    DECLARE c INT;
    DECLARE d INT;
    DECLARE e INT;
    DECLARE f INT;
    DECLARE g INT;
    DECLARE h INT;
    DECLARE i INT;
    DECLARE k INT;
    DECLARE l INT;
    DECLARE m INT;
    DECLARE jour_paques INT;
    DECLARE mois_paques INT;
    DECLARE date_paques DATE;

    -- Algorithme de Meeus/Jones/Butcher
    SET a = p_annee MOD 19;
    SET b = FLOOR(p_annee / 100);
    SET c = p_annee MOD 100;
    SET d = FLOOR(b / 4);
    SET e = b MOD 4;
    SET f = FLOOR((b + 8) / 25);
    SET g = FLOOR((b - f + 1) / 3);
    SET h = (19 * a + b - d - g + 15) MOD 30;
    SET i = FLOOR(c / 4);
    SET k = c MOD 4;
    SET l = (32 + 2 * e + 2 * i - h - k) MOD 7;
    SET m = FLOOR((a + 11 * h + 22 * l) / 451);
    SET mois_paques = FLOOR((h + l - 7 * m + 114) / 31);
    SET jour_paques = ((h + l - 7 * m + 114) MOD 31) + 1;

    SET date_paques = MAKEDATE(p_annee, 1) 
                      + INTERVAL (mois_paques - 1) MONTH 
                      + INTERVAL (jour_paques - 1) DAY;

    -- Insérer dans paques_annuel (ignore si l'année existe déjà)
    INSERT IGNORE INTO paques_annuel (annee, date_paques)
    VALUES (p_annee, date_paques);

    -- Insérer les 3 jours fériés mobiles dérivés de Pâques
    -- id_mobile 1 = Lundi de Pâques     (+1 jour)
    -- id_mobile 2 = Ascension           (+39 jours)
    -- id_mobile 3 = Lundi de Pentecôte  (+50 jours)
    INSERT IGNORE INTO jours_feries_mobiles (id_mobile, annee, date_ferie)
    VALUES
        (1, p_annee, DATE_ADD(date_paques, INTERVAL 1  DAY)),
        (2, p_annee, DATE_ADD(date_paques, INTERVAL 39 DAY)),
        (3, p_annee, DATE_ADD(date_paques, INTERVAL 50 DAY));

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `equipe`
--

DROP TABLE IF EXISTS `equipe`;
CREATE TABLE IF NOT EXISTS `equipe` (
  `id_equipe` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom_equipe` varchar(255) NOT NULL,
  `specialisation` varchar(255) NOT NULL,
  `capacite` int NOT NULL,
  `chef_de_equipe` int NOT NULL,
  `parent_id` int DEFAULT NULL,
  `date_debut` date NOT NULL DEFAULT (curdate()),
  `date_fin` date DEFAULT NULL,
  PRIMARY KEY (`id_equipe`),
  UNIQUE KEY `id_equipe` (`id_equipe`),
  KEY `chef_de_equipe` (`chef_de_equipe`),
  KEY `parent_id` (`parent_id`)
) ENGINE=MyISAM AUTO_INCREMENT=35 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `equipe`
--

INSERT INTO `equipe` (`id_equipe`, `nom_equipe`, `specialisation`, `capacite`, `chef_de_equipe`, `parent_id`, `date_debut`, `date_fin`) VALUES
(1, 'Equipe Maçonnerie A', 'Maçonnerie', 8, 2, NULL, '2016-01-01', NULL),
(2, 'Equipe Electricité A', 'Electricité', 8, 2, NULL, '2016-01-01', NULL),
(3, 'Equipe Plomberie A', 'Plomberie', 8, 3, NULL, '2016-01-01', NULL),
(4, 'Sous-Equipe Maçonnerie B1', 'Maçonnerie', 5, 4, 1, '2016-01-01', NULL),
(5, 'Sous-Equipe Electricité B1', 'Electricité', 4, 5, 2, '2016-01-01', NULL),
(6, 'Equipe Finition', 'Finition', 8, 6, NULL, '2016-01-01', NULL),
(7, 'Equipe Toiture A', 'Toiture', 8, 13, NULL, '2016-01-01', NULL),
(8, 'Equipe Voirie A', 'Voirie', 8, 14, NULL, '2016-01-01', NULL),
(9, 'Equipe Isolation A', 'Isolation', 8, 15, NULL, '2016-01-01', NULL),
(10, 'Sous-Equipe Voirie B1', 'Voirie', 5, 16, 8, '2016-01-01', NULL),
(11, 'Sous-Equipe Toiture B1', 'Toiture', 4, 41, 7, '2016-01-01', NULL),
(12, 'Equipe Carrelage', 'Carrelage', 8, 18, NULL, '2016-01-01', NULL),
(13, 'Equipe Peinture', 'Peinture', 8, 19, NULL, '2016-01-01', NULL),
(14, 'Sous-Equipe Isolation B1', 'Isolation', 4, 20, 9, '2016-01-01', NULL),
(29, 'Equipe Maçonnerie B', 'Maçonnerie', 6, 7, NULL, '2016-01-01', NULL),
(30, 'Sous-Equipe Finition', 'Finition', 5, 6, 6, '2016-01-01', NULL),
(31, 'Sous-Equipe Carrelage', 'Carrelage', 5, 7, NULL, '2016-01-01', NULL),
(32, 'Equipe Démolition', 'Démolition', 6, 42, NULL, '2016-01-01', '2026-03-31'),
(33, 'Mini-Equipe Voirie C1', 'Voirie', 3, 40, 10, '2016-01-01', NULL),
(34, 'test', 'testing', 4, 1, NULL, '2026-06-19', '2026-06-19');

--
-- Triggers `equipe`
--
DROP TRIGGER IF EXISTS `trg_equipe_chef_delete`;
DELIMITER $$
CREATE TRIGGER `trg_equipe_chef_delete` AFTER DELETE ON `equipe` FOR EACH ROW BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM equipe
        WHERE chef_de_equipe = OLD.chef_de_equipe
    ) THEN
        UPDATE travailleur
        SET privileges = 'travailleur'
        WHERE id_travailleur = OLD.chef_de_equipe
          AND privileges = 'chef_equipe';
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_equipe_chef_promote`;
DELIMITER $$
CREATE TRIGGER `trg_equipe_chef_promote` AFTER INSERT ON `equipe` FOR EACH ROW BEGIN
    -- Promote privileges if plain travailleur
    UPDATE travailleur
    SET privileges = 'chef_equipe'
    WHERE id_travailleur = NEW.chef_de_equipe
      AND privileges = 'travailleur';

    -- Insert chef into travailleur_equipe
    INSERT INTO travailleur_equipe (id_equipe, id_travailleur, role, date_debut, date_fin)
    VALUES (NEW.id_equipe, NEW.chef_de_equipe, 'chef', CURDATE(), NULL)
    ON DUPLICATE KEY UPDATE role = 'chef', date_debut = CURDATE(), date_fin = NULL;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_equipe_chef_update`;
DELIMITER $$
CREATE TRIGGER `trg_equipe_chef_update` AFTER UPDATE ON `equipe` FOR EACH ROW BEGIN
    IF NEW.chef_de_equipe <> OLD.chef_de_equipe THEN

        -- Promote new chef
        UPDATE travailleur
        SET privileges = 'chef_equipe'
        WHERE id_travailleur = NEW.chef_de_equipe
          AND privileges = 'travailleur';

        -- Insert new chef into travailleur_equipe
        INSERT INTO travailleur_equipe (id_equipe, id_travailleur, role, date_debut, date_fin)
        VALUES (NEW.id_equipe, NEW.chef_de_equipe, 'chef', CURDATE(), NULL)
        ON DUPLICATE KEY UPDATE role = 'chef', date_debut = CURDATE(), date_fin = NULL;
        
        UPDATE travailleur_equipe 
        	SET date_fin = CURRENT_DATE 
            	WHERE id_travailleur = old.chef_de_equipe 
                and id_equipe = new.id_equipe;

        -- Demote old chef if no longer chef of any team
        IF NOT EXISTS (
            SELECT 1 FROM equipe
            WHERE chef_de_equipe = OLD.chef_de_equipe
              AND id_equipe <> OLD.id_equipe
        ) THEN
            UPDATE travailleur
            SET privileges = 'travailleur'
            WHERE id_travailleur = OLD.chef_de_equipe
              AND privileges = 'chef_equipe';
        END IF;

    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `feries_mobiles`
--

DROP TABLE IF EXISTS `feries_mobiles`;
CREATE TABLE IF NOT EXISTS `feries_mobiles` (
  `id_ferie` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom_ferie` varchar(255) NOT NULL,
  `decalage_jours` int NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date DEFAULT NULL,
  `legal` tinyint NOT NULL DEFAULT '1',
  PRIMARY KEY (`id_ferie`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `feries_mobiles`
--

INSERT INTO `feries_mobiles` (`id_ferie`, `nom_ferie`, `decalage_jours`, `date_debut`, `date_fin`, `legal`) VALUES
(1, 'Lundi de Pâques', 1, '2000-01-01', NULL, 1),
(2, 'Ascension', 39, '2000-01-01', NULL, 1),
(3, 'Lundi de Pentecôte', 50, '2000-01-01', NULL, 1),
(4, 'Vendredi Saint', -2, '2018-01-01', '2022-12-31', 0);

-- --------------------------------------------------------

--
-- Table structure for table `heures`
--

DROP TABLE IF EXISTS `heures`;
CREATE TABLE IF NOT EXISTS `heures` (
  `id_travailleur` bigint NOT NULL,
  `mois` int NOT NULL,
  `annee` int NOT NULL,
  `1` varchar(10) DEFAULT NULL,
  `2` varchar(10) DEFAULT NULL,
  `3` varchar(10) DEFAULT NULL,
  `4` varchar(10) DEFAULT NULL,
  `5` varchar(10) DEFAULT NULL,
  `6` varchar(10) DEFAULT NULL,
  `7` varchar(10) DEFAULT NULL,
  `8` varchar(10) DEFAULT NULL,
  `9` varchar(10) DEFAULT NULL,
  `10` varchar(10) DEFAULT NULL,
  `11` varchar(10) DEFAULT NULL,
  `12` varchar(10) DEFAULT NULL,
  `13` varchar(10) DEFAULT NULL,
  `14` varchar(10) DEFAULT NULL,
  `15` varchar(10) DEFAULT NULL,
  `16` varchar(10) DEFAULT NULL,
  `17` varchar(10) DEFAULT NULL,
  `18` varchar(10) DEFAULT NULL,
  `19` varchar(10) DEFAULT NULL,
  `20` varchar(10) DEFAULT NULL,
  `21` varchar(10) DEFAULT NULL,
  `22` varchar(10) DEFAULT NULL,
  `23` varchar(10) DEFAULT NULL,
  `24` varchar(10) DEFAULT NULL,
  `25` varchar(10) DEFAULT NULL,
  `26` varchar(10) DEFAULT NULL,
  `27` varchar(10) DEFAULT NULL,
  `28` varchar(10) DEFAULT NULL,
  `29` varchar(10) DEFAULT NULL,
  `30` varchar(10) DEFAULT NULL,
  `31` varchar(10) DEFAULT NULL,
  PRIMARY KEY (`id_travailleur`,`mois`,`annee`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `heures`
--

INSERT INTO `heures` (`id_travailleur`, `mois`, `annee`, `1`, `2`, `3`, `4`, `5`, `6`, `7`, `8`, `9`, `10`, `11`, `12`, `13`, `14`, `15`, `16`, `17`, `18`, `19`, `20`, `21`, `22`, `23`, `24`, `25`, `26`, `27`, `28`, `29`, `30`, `31`) VALUES
(31, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(30, 1, 2026, NULL, '8', NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, '8', '8', NULL, 'C', 'C', NULL, NULL, 'C', 'C', '8', NULL, '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL),
(29, 1, 2026, NULL, 'M', NULL, NULL, 'M', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(28, 1, 2026, NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, 'C', NULL, NULL, '8', '8', NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL),
(27, 1, 2026, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, 'M', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL),
(26, 1, 2026, NULL, 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL),
(25, 1, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', 'P', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'M', 'P', NULL, NULL),
(24, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(23, 1, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, 'C', NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, 'M', '8', '8', NULL, NULL, NULL),
(9, 6, 2026, NULL, NULL, NULL, NULL, NULL, '4', '4', NULL, 'C', '6', NULL, '5', 'P', '5', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 6, 2026, NULL, NULL, NULL, NULL, '7', '5', '7', NULL, 'C', '3', '5', 'P', NULL, 'P', NULL, NULL, '5', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(10, 6, 2026, NULL, NULL, NULL, NULL, NULL, 'CC', 'P', NULL, '', NULL, NULL, '6', '6', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 7, 2026, NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 8, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 9, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 10, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 11, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 12, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(22, 1, 2026, NULL, '8', NULL, NULL, NULL, NULL, 'A', NULL, 'CS', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, 'A', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, NULL, NULL),
(21, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(20, 1, 2026, NULL, '8', NULL, NULL, '8', 'M', 'M', 'M', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL),
(3, 6, 2026, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, '', 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(1, 6, 2026, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '4', '4', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(4, 6, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '', '6', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(19, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(18, 1, 2026, NULL, NULL, NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL),
(7, 6, 2026, '8', '8', '8', '8', '7', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(8, 6, 2026, '8', '8', 'CC', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(12, 6, 2026, '8', '8', '8', '8', '8', NULL, NULL, 'M', 'M', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(17, 1, 2026, NULL, '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'M', '8', NULL),
(16, 1, 2026, NULL, NULL, NULL, NULL, '8', NULL, 'M', '8', '8', NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, NULL, 'CC', 'C', NULL, 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(15, 1, 2026, NULL, '8', NULL, NULL, 'R', '8', 'C', 'C', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(14, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL),
(13, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(12, 1, 2026, NULL, '8', NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', '8', NULL, 'C', NULL, NULL, NULL, 'C', NULL, NULL, 'C', 'C', NULL, NULL, '8', '8', NULL, NULL, '8', NULL),
(23, 6, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(11, 1, 2026, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, 'M', NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(10, 1, 2026, NULL, 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(9, 1, 2026, NULL, '8', NULL, NULL, '8', '8', NULL, 'CE', 'CE', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL),
(8, 1, 2026, NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL),
(7, 1, 2026, NULL, '8', NULL, NULL, '8', 'C', 'C', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, 'M', '8', NULL, NULL, '8', NULL),
(6, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(5, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'CI', 'CI', 'CI', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(4, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(3, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', 'M', 'M', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(2, 1, 2026, NULL, '8', NULL, NULL, 'R', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C', 'C', 'C', 'C', NULL),
(1, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(32, 1, 2026, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, 'P', NULL, NULL, NULL, 'CC', NULL, 'P', 'M', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'M', NULL),
(33, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', 'C', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(34, 1, 2026, NULL, NULL, NULL, NULL, '8', NULL, 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL),
(35, 1, 2026, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', NULL, NULL, '8', '8', NULL),
(36, 1, 2026, NULL, '8', NULL, NULL, '8', '8', 'AT', 'AT', 'AT', NULL, NULL, 'AT', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(37, 1, 2026, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL),
(38, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(39, 1, 2026, NULL, NULL, NULL, NULL, NULL, NULL, 'P', 'P', NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, 'C', NULL, NULL, NULL, NULL, NULL, 'P', 'P', NULL, NULL),
(40, 1, 2026, NULL, 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL),
(41, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'R', '8', 'C', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(42, 1, 2026, NULL, NULL, NULL, NULL, '8', '8', 'M', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(43, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, 'C', '8', '8', NULL, '8', NULL, NULL, '8', 'M', 'M', NULL, 'M', NULL),
(44, 1, 2026, NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C', 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL),
(45, 1, 2026, NULL, NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL),
(46, 1, 2026, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL),
(1, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, NULL, NULL),
(2, 2, 2026, NULL, '8', 'M', '8', '8', 'R', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', 'C', 'C', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(3, 2, 2026, NULL, '8', '8', '8', 'M', 'M', NULL, NULL, 'M', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(4, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(5, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'CI', NULL, NULL, 'CI', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(6, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(7, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, NULL, '8', 'C', 'C', 'C', NULL, NULL, NULL, NULL),
(8, 2, 2026, NULL, NULL, 'AT', 'AT', 'AT', 'AT', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'AT', NULL, '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, NULL, NULL),
(9, 2, 2026, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', NULL, NULL, '8', 'CI', NULL, NULL, 'CI', '8', '8', '8', NULL, NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, NULL, NULL),
(10, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(11, 2, 2026, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, 'M', '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, 'C', '8', NULL, NULL, NULL, NULL, NULL),
(12, 2, 2026, NULL, NULL, '8', 'R', '8', NULL, NULL, NULL, NULL, '8', 'C', NULL, NULL, NULL, NULL, NULL, NULL, 'C', 'C', '8', NULL, NULL, '8', 'M', '8', '8', NULL, NULL, NULL, NULL, NULL),
(13, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(14, 2, 2026, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(15, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', 'C', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(16, 2, 2026, NULL, '8', NULL, '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, '8', 'C', 'C', NULL, 'C', NULL, NULL, 'M', '8', NULL, '8', '8', NULL, NULL, NULL, NULL),
(17, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(18, 2, 2026, NULL, '8', '8', NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, NULL),
(19, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(20, 2, 2026, NULL, 'M', NULL, 'M', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(21, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(22, 2, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, 'A', '8', NULL, NULL, '8', NULL, NULL, NULL, NULL),
(23, 2, 2026, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, 'M', '8', '8', NULL, NULL, NULL, '8', NULL, 'C', NULL, 'C', NULL, NULL, NULL, NULL),
(24, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(25, 2, 2026, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, 'C', 'C', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(26, 2, 2026, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, NULL, NULL),
(27, 2, 2026, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', 'CC', '8', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL),
(28, 2, 2026, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, '8', NULL, '8', NULL, NULL, 'M', NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL),
(29, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'M', 'M', 'M', 'M', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(30, 2, 2026, NULL, '8', '8', '8', '8', NULL, NULL, NULL, 'R', NULL, '8', NULL, NULL, NULL, NULL, '8', '8', 'C', NULL, 'C', NULL, NULL, '8', NULL, 'M', NULL, '8', NULL, NULL, NULL, NULL),
(31, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(32, 2, 2026, NULL, NULL, NULL, NULL, 'M', 'M', NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, 'M', NULL, NULL, 'M', NULL, NULL, 'CC', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(33, 2, 2026, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(34, 2, 2026, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL),
(35, 2, 2026, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8', NULL, 'C', NULL, NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL),
(36, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'M', 'M', NULL, NULL, 'M', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(37, 2, 2026, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, NULL),
(38, 2, 2026, NULL, '8', '8', '8', 'C', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(39, 2, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CC', NULL, 'P', 'P', NULL, NULL, 'P', 'P', NULL, NULL, 'P', NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(40, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(41, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'C', 'C', NULL, NULL, 'C', 'C', 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL),
(42, 2, 2026, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', '8', '8', '8', NULL, NULL, NULL, NULL),
(43, 2, 2026, NULL, NULL, '8', 'CC', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, 'C', '8', '8', NULL, 'M', NULL, NULL, 'M', NULL, 'M', '8', '8', NULL, NULL, NULL, NULL),
(44, 2, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, NULL, NULL),
(45, 2, 2026, NULL, NULL, '8', NULL, 'CC', NULL, NULL, NULL, NULL, '8', 'C', NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL),
(46, 2, 2026, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL),
(1, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(2, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', 'C', 'C', 'C', NULL, NULL, 'C', 'C'),
(3, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'M', 'M', 'M', 'M', '8', NULL, NULL, 'CC', '8'),
(4, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '9', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(5, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(6, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(7, 3, 2026, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(8, 3, 2026, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, 'M', NULL, NULL, NULL, NULL, 'M', 'M', NULL, 'M', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8'),
(9, 3, 2026, NULL, 'CE', 'CE', '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, '8', NULL),
(10, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(11, 3, 2026, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, 'M', NULL, NULL, 'M', NULL, NULL, NULL, NULL, 'M', '8', NULL, NULL, NULL, NULL, NULL, NULL),
(12, 3, 2026, NULL, '8', '8', NULL, '8', '8', NULL, NULL, '8', NULL, 'C', NULL, 'C', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, NULL),
(13, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'CC', '8'),
(14, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(15, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'R', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', 'C', '8', NULL, NULL, '8', '8'),
(16, 3, 2026, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL),
(17, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', 'C', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(18, 3, 2026, NULL, 'C', 'C', 'C', '8', '8', NULL, NULL, '8', NULL, 'M', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, '8'),
(19, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '10', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C'),
(20, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'M', NULL, NULL, 'M', NULL),
(21, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', 'M', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(22, 3, 2026, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, NULL, NULL, 'CS', '8', 'A', NULL, NULL, '8', '8'),
(23, 3, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, NULL, NULL, 'C', NULL, 'C', NULL, NULL, NULL, 'C', '8', NULL, '8', NULL, NULL, '8', '8'),
(24, 3, 2026, NULL, '8', '8', '8', '8', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'CC', NULL, NULL, '8', 'C', '8', '8', '8', NULL, NULL, '8', '8'),
(25, 3, 2026, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, 'P', NULL, 'C', NULL, NULL, NULL, NULL, 'C', NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL),
(26, 3, 2026, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD'),
(27, 3, 2026, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', 'CC', NULL, '8', '8', NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', 'C', 'C', 'C', NULL, NULL, NULL, NULL),
(28, 3, 2026, NULL, 'CC', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL),
(29, 3, 2026, NULL, '8', 'M', 'M', 'M', 'M', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'CC', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C'),
(30, 3, 2026, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL, '8', NULL, 'C', NULL, NULL, NULL, 'C', NULL, NULL, 'C', NULL, NULL, 'C', '8'),
(31, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '9', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(32, 3, 2026, NULL, 'M', 'M', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'M', 'M', NULL, NULL, NULL, 'CC', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL),
(33, 3, 2026, NULL, '8', '8', '8', '8', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'CC', '8', '8', NULL, NULL, '8', '8'),
(34, 3, 2026, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', '8', '8', 'CS', NULL, NULL, NULL, 'CS', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(35, 3, 2026, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', NULL, '8', 'CC', NULL, NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, '8'),
(36, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(37, 3, 2026, NULL, 'C', NULL, '8', '8', 'M', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, NULL, '8'),
(38, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(39, 3, 2026, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, 'CC', 'P', NULL, NULL, NULL, NULL, 'P', NULL),
(40, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(41, 3, 2026, NULL, '8', '8', '8', 'C', 'C', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(42, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8'),
(43, 3, 2026, NULL, '8', '8', 'C', '8', '8', NULL, NULL, 'CC', 'M', 'M', 'M', 'M', NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, '8', NULL),
(44, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8'),
(45, 3, 2026, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, '8'),
(46, 3, 2026, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'C', 'C', NULL, NULL, 'C', NULL),
(1, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, 'C', 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(2, 4, 2026, NULL, 'C', 'C', NULL, NULL, NULL, 'C', 'C', 'C', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(3, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', 'M', 'M', NULL),
(4, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, 'R', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '9', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(5, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(6, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(7, 4, 2026, NULL, '8', NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, NULL, 'C', 'C', NULL, NULL),
(8, 4, 2026, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL),
(9, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', 'C', 'C', NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, '8', NULL, NULL),
(10, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(11, 4, 2026, NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, 'M', NULL, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, '8', NULL, '8', NULL),
(12, 4, 2026, NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, 'C', NULL, NULL, 'C', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', 'R', '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL),
(13, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(14, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(15, 4, 2026, NULL, '8', 'C', NULL, NULL, NULL, 'C', 'C', 'C', 'C', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, 'R', '8', '8', '8', NULL),
(16, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', NULL, '8', NULL, '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, '8', NULL, '8', NULL, NULL),
(17, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(18, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, '8', NULL),
(19, 4, 2026, NULL, '10', '8', NULL, NULL, NULL, 'R', '8', '8', 'C', NULL, NULL, 'C', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(20, 4, 2026, NULL, 'M', 'M', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', 'C', '8', '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8', NULL, '8', NULL),
(21, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(22, 4, 2026, NULL, '8', 'A', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, 'A', NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(23, 4, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, 'C', NULL, NULL, 'C', 'C', 'C', NULL, '8', NULL, NULL, NULL, 'R', NULL, NULL, NULL, NULL, NULL, '8', NULL, '8', '8', NULL),
(24, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(25, 4, 2026, NULL, 'C', NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, NULL, 'P', NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(26, 4, 2026, NULL, 'MLD', 'MLD', NULL, NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', NULL),
(27, 4, 2026, NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', NULL, NULL),
(28, 4, 2026, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, '8', '8', NULL, NULL, NULL, '8', NULL, NULL, 'C', NULL, NULL, NULL, NULL, NULL, 'C', 'CC', NULL),
(29, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'CC', NULL, NULL, '8', '8', '8', 'M', 'M', NULL, NULL, '8', '8', '8', '8', NULL),
(30, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', NULL, NULL, '8', NULL, NULL, '8', NULL, 'C', 'C', NULL, NULL, NULL, 'C', NULL, '8', '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL),
(31, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '9', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(32, 4, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CC', NULL, NULL, NULL, NULL, 'P', 'M', NULL, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, 'M', NULL, 'P', NULL),
(33, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(34, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, '8', 'CS', 'CS', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(35, 4, 2026, NULL, NULL, '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, NULL, '8', NULL, '8', 'C', NULL, NULL, NULL, 'C', NULL, 'C', NULL),
(36, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(37, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, '8', NULL, 'C', NULL, 'C', NULL, NULL, 'C', NULL, NULL, '8', NULL),
(38, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(39, 4, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', 'P', NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, 'P', NULL, NULL, 'P', 'P', NULL, NULL, NULL),
(40, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(41, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', 'R', 'M', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'C', 'C', 'C', NULL),
(42, 4, 2026, NULL, NULL, '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', 'C', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL),
(43, 4, 2026, NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', NULL, '8', 'M', NULL, NULL, 'M', 'M', 'M', '8', NULL),
(44, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', '8', NULL),
(45, 4, 2026, NULL, 'CC', '8', NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL),
(46, 4, 2026, NULL, '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, 'CC', '8', NULL, NULL, 'M', NULL, NULL, '8', NULL, NULL, NULL, NULL),
(1, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(2, 5, 2026, NULL, NULL, NULL, '8', 'C', 'C', 'C', 'C', NULL, NULL, 'R', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(3, 5, 2026, NULL, NULL, NULL, '8', 'M', 'M', 'M', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', 'CC', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(4, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(5, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(6, 5, 2026, NULL, NULL, NULL, '8', '8', 'C', 'C', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(7, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', 'C', 'C', NULL, 'C', NULL, NULL, NULL, 'CC', '8', 'M', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL),
(8, 5, 2026, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, 'C', '8', '8', '8', NULL, NULL),
(9, 5, 2026, NULL, NULL, NULL, '8', NULL, '8', 'C', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(10, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(11, 5, 2026, NULL, NULL, NULL, 'M', NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, 'M', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(12, 5, 2026, NULL, NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, 'C', 'C', NULL, NULL, NULL, NULL, 'C', 'C', 'C', NULL, NULL),
(13, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', 'C', 'C', '8', NULL, NULL),
(14, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(15, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, 'C', NULL, NULL, 'C', 'C', 'C', 'C', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(16, 5, 2026, NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', NULL, NULL, '8', '8', '8', 'C', NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(17, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, 'C', 'C', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(18, 5, 2026, NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', 'C', 'C', NULL, '8', NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL),
(19, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', 'R', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', 'C', '8', '8', NULL, NULL),
(20, 5, 2026, NULL, NULL, NULL, NULL, '8', '8', '8', 'M', NULL, NULL, 'M', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(21, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(22, 5, 2026, NULL, NULL, NULL, 'CS', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'A', NULL, '8', NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL),
(23, 5, 2026, NULL, NULL, NULL, NULL, 'C', 'C', NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, 'C', NULL, NULL, NULL, 'C', 'R', NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL),
(24, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', 'CC', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', 'M', NULL, NULL),
(25, 5, 2026, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, 'P', NULL, 'P', NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(26, 5, 2026, NULL, NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', NULL, 'MLD', NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL, NULL, 'MLD', 'MLD', 'MLD', 'MLD', NULL, NULL),
(27, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, 'CC', '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', '8', NULL, NULL),
(28, 5, 2026, NULL, NULL, NULL, '8', NULL, '8', NULL, NULL, NULL, NULL, '8', '8', 'M', NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL),
(29, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', 'M', 'M', NULL, 'M', NULL, NULL, 'M', '8', '8', 'CC', 'C', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(30, 5, 2026, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, NULL, '8', 'M', NULL, NULL, NULL, NULL, 'C', 'C', 'C', 'C', '8', NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL),
(31, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(32, 5, 2026, NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL, 'M', NULL, NULL, NULL, NULL, NULL, 'M', NULL, NULL, NULL),
(33, 5, 2026, NULL, NULL, NULL, '8', '8', 'C', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(34, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', NULL, '8', NULL, '8', NULL, NULL, NULL, 'C', '8', NULL, NULL, NULL, NULL),
(35, 5, 2026, NULL, NULL, NULL, NULL, '8', 'C', 'C', '8', NULL, NULL, '8', '8', '8', NULL, NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL),
(36, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(37, 5, 2026, NULL, NULL, NULL, NULL, 'M', '8', '8', '8', NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL, NULL, NULL, NULL, '8', '8', NULL, NULL),
(38, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', 'C', 'C', 'C', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(39, 5, 2026, NULL, NULL, NULL, 'P', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, NULL, NULL, 'C', NULL, NULL, NULL, NULL, NULL, NULL, 'P', NULL, 'P', 'P', NULL, NULL),
(40, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(41, 5, 2026, NULL, NULL, NULL, 'C', 'C', 'C', 'C', 'C', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, 'R', '8', '8', '8', NULL, NULL),
(42, 5, 2026, NULL, NULL, NULL, '8', NULL, '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(43, 5, 2026, NULL, NULL, NULL, '8', '8', NULL, NULL, '8', NULL, NULL, '8', '8', '8', NULL, 'M', NULL, NULL, 'M', 'M', '8', NULL, '8', NULL, NULL, NULL, '8', '8', NULL, '8', NULL, NULL),
(44, 5, 2026, NULL, NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, '8', '8', '8', NULL, '8', NULL, NULL, '8', '8', '8', '8', '8', NULL, NULL, NULL, '8', '8', '8', '8', NULL, NULL),
(45, 5, 2026, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '8', NULL, NULL, '8', '8', NULL, NULL, NULL, 'C', NULL, '8', '8', NULL, NULL),
(46, 5, 2026, NULL, NULL, NULL, '8', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'CC', '8', NULL, NULL, NULL, NULL, '8', NULL, '8', NULL, '8', NULL, NULL, NULL, '8', '8', '8', NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `jours_feries_fixes`
--

DROP TABLE IF EXISTS `jours_feries_fixes`;
CREATE TABLE IF NOT EXISTS `jours_feries_fixes` (
  `id_ferie` bigint NOT NULL AUTO_INCREMENT,
  `nom_ferie` varchar(255) NOT NULL,
  `event_date` date NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date DEFAULT NULL,
  `legal` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`id_ferie`)
) ;

--
-- Dumping data for table `jours_feries_fixes`
--

INSERT INTO `jours_feries_fixes` (`id_ferie`, `nom_ferie`, `event_date`, `date_debut`, `date_fin`, `legal`) VALUES
(1, 'Nouvel An', '1900-01-01', '1890-01-01', NULL, 1),
(2, 'Fête du Travail', '1900-05-01', '1890-01-01', NULL, 1),
(3, 'Fête Nationale Belge', '1900-07-21', '1890-01-01', NULL, 1),
(4, 'Assomption', '1900-08-15', '1890-01-01', NULL, 1),
(5, 'Toussaint', '1900-11-01', '1890-01-01', NULL, 1),
(6, 'Armistice', '1900-11-11', '1918-11-11', NULL, 1),
(7, 'Noël', '1900-12-25', '1890-01-01', NULL, 1),
(8, 'Fermeture annuelle chantier', '1900-08-16', '2024-01-01', NULL, 1),
(9, 'Pont commercial mai', '1900-05-02', '2024-01-01', NULL, 1),
(10, 'anniversaire Entreprise', '1900-04-01', '2026-01-12', '2026-06-19', 0),
(11, 'Pont de Noël', '1900-12-26', '2019-01-01', '2023-12-31', 0),
(12, 'Journée cohésion d\'équipe', '1900-09-15', '2022-01-01', '2024-12-31', 0);

-- --------------------------------------------------------

--
-- Table structure for table `jours_feries_mobiles`
--

DROP TABLE IF EXISTS `jours_feries_mobiles`;
CREATE TABLE IF NOT EXISTS `jours_feries_mobiles` (
  `id_ferie` bigint UNSIGNED NOT NULL,
  `annee` int NOT NULL,
  `date_ferie` date NOT NULL,
  PRIMARY KEY (`annee`,`date_ferie`),
  KEY `id_mobile` (`id_ferie`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `jours_feries_mobiles`
--

INSERT INTO `jours_feries_mobiles` (`id_ferie`, `annee`, `date_ferie`) VALUES
(1, 2025, '2025-04-21'),
(2, 2025, '2025-05-29'),
(3, 2025, '2025-06-09'),
(1, 2026, '2026-04-06'),
(2, 2026, '2026-05-14'),
(3, 2026, '2026-05-25'),
(1, 2027, '2027-03-29'),
(2, 2027, '2027-05-06'),
(3, 2027, '2027-05-17'),
(1, 2028, '2028-04-17'),
(2, 2028, '2028-05-25'),
(3, 2028, '2028-06-05'),
(1, 2022, '2022-04-18'),
(2, 2022, '2022-05-26'),
(3, 2022, '2022-06-06'),
(1, 2023, '2023-04-10'),
(2, 2023, '2023-05-18'),
(3, 2023, '2023-05-29'),
(1, 2024, '2024-04-01'),
(2, 2024, '2024-05-09'),
(3, 2024, '2024-05-20');

-- --------------------------------------------------------

--
-- Table structure for table `log_evolution_code_heure`
--

DROP TABLE IF EXISTS `log_evolution_code_heure`;
CREATE TABLE IF NOT EXISTS `log_evolution_code_heure` (
  `id_code` bigint UNSIGNED NOT NULL,
  `nom_code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `valeur` decimal(10,0) NOT NULL,
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date DEFAULT NULL,
  PRIMARY KEY (`id_code`,`date_debut`)
) ENGINE=MyISAM AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `log_evolution_code_heure`
--

INSERT INTO `log_evolution_code_heure` (`id_code`, `nom_code`, `valeur`, `description`, `date_debut`, `date_fin`) VALUES
(1, 'P', 1, 'Prestation sur le chantier', '1971-03-16', NULL),
(2, 'C', 1, 'Congés payés', '1971-03-16', NULL),
(3, 'CC', 1, 'Congés de circonstance', '1978-07-03', NULL),
(4, 'CS', 0, 'Congé sans solde', '1978-07-03', NULL),
(5, 'M', 1, 'Congé maladie', '1978-07-03', NULL),
(6, 'MLD', 0, 'Congé maladie longue durée', '1978-07-03', NULL),
(7, 'CE', 0, 'Chômage économique', '1944-12-28', NULL),
(8, 'CI', 0, 'Chômage intempérie', '1969-06-27', NULL),
(9, 'AT', 1, 'Accident de travail', '1971-04-10', NULL),
(10, 'R', 1, 'Récupération des heures supplémentaires', '1971-03-16', NULL),
(11, 'A', 0, 'Absence non justifiée', '1978-07-03', NULL),
(13, 'CPE', 1, 'Congé-éducation payé (formation interne)', '1985-01-01', '2004-12-31'),
(12, 'T', 1, 'Accident de trajet', '1971-04-10', '2015-06-30'),
(13, 'CPE', 1, 'Congé-éducation payé', '2005-01-01', '2022-06-30'),
(14, 'CHO', 0, 'Chômage temporaire complet', '1945-01-01', '1979-12-31');

-- --------------------------------------------------------

--
-- Table structure for table `paques_annuel`
--

DROP TABLE IF EXISTS `paques_annuel`;
CREATE TABLE IF NOT EXISTS `paques_annuel` (
  `annee` int NOT NULL,
  `date_paques` date NOT NULL,
  PRIMARY KEY (`annee`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `paques_annuel`
--

INSERT INTO `paques_annuel` (`annee`, `date_paques`) VALUES
(2025, '2025-04-20'),
(2026, '2026-04-05'),
(2027, '2027-03-28'),
(2028, '2028-04-16'),
(2022, '2022-04-17'),
(2023, '2023-04-09'),
(2024, '2024-03-31');

-- --------------------------------------------------------

--
-- Table structure for table `travailleur`
--

DROP TABLE IF EXISTS `travailleur`;
CREATE TABLE IF NOT EXISTS `travailleur` (
  `id_travailleur` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `privileges` enum('travailleur','contremaitre/manager','admin','chef_equipe') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'travailleur',
  `nom` varchar(255) NOT NULL,
  `no_registre_national` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `password` varchar(255) NOT NULL,
  `session_token` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id_travailleur`),
  UNIQUE KEY `id_travailleur` (`id_travailleur`),
  UNIQUE KEY `no_registre_national` (`no_registre_national`)
) ENGINE=MyISAM AUTO_INCREMENT=48 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `travailleur`
--

INSERT INTO `travailleur` (`id_travailleur`, `privileges`, `nom`, `no_registre_national`, `email`, `password`, `session_token`) VALUES
(15, 'contremaitre/manager', 'Lucas Bernard', '87.09.09-258.36', 'lucas.bernard@mail.com', '$2y$10$cK5X.iNSOtQvNXJnX0MpheIWx2oYal/s5Dd5XrOPQynCnzQz.wipq', NULL),
(2, 'admin', 'testing', '00.00.00-000.00', 'test@test.com', '$2y$10$KRuTDUICjANwXcQ5n13wnehH/2zNoeaEVt9dIDDBBtJNT0jy9NYRy', 'bc552bcbdef98c283275b7d542773d967bf0b764b8c0fe82de7b10d7ee017561'),
(14, 'contremaitre/manager', 'Marie Lambert', '81.09.21-654.22', 'marie.lambert@mail.com', '$2y$10$lQeAqEOzIzwh9UeuZzgkGeRlmAuTV1WlTPoI53.5W2phIb4Qj0up.', NULL),
(13, 'contremaitre/manager', 'Jean Dupont', '84.63.24-324.55', 'jean.dupont@mail.com', '$2y$10$aWA3QF.N6X5p6QRx5YuBCub3alMJiUA8Y/76ynbAMChSgmzJNPolK', NULL),
(16, 'contremaitre/manager', 'Sophie Martin', '88.11.03-741.25', 'sophie.martin@mail.com', '$2y$10$3kfFAg8eXWX6uH4thoeEt.k.FCuuCsWYIuxMSZAEyAp99WwyZL99G', NULL),
(17, 'contremaitre/manager', 'Thomas Leroy', '92.01.17-963.14', 'thomas.leroy@mail.com', '$2y$10$WW8gk0ft8EEqlclCUp8lCeyUpz.zoLzFpit0/O8phYnD9aTtl6FVS', NULL),
(18, 'contremaitre/manager', 'Emma Petit', '86.07.23-357.47', 'emma.petit@mail.com', '$2y$10$7mC4As2M.UHZSyqSU5TiS.Q2qGyNPOjNwEpTtX6uHV3m90Mx8S.GO', NULL),
(19, 'contremaitre/manager', 'Nicolas Henry', '86.03.14-852.96', 'nicolas.henry@mail.com', '$2y$10$2mC/qSrEDf6GufeN7VD7M..k4YA4.xmayzsUgWg.3975qNT/ydteO', NULL),
(20, 'contremaitre/manager', 'Laura Simon', '88.05.14-468.50', 'laura.simon@mail.com', '$2y$10$H3yfROCqqXYkRlx8sbfC6.Uk3EEXHCqsbaRUJw2fajhxv7DAsZgdu', NULL),
(21, 'travailleur', 'Olivier Janssens', '84.01.11-214.55', 'olivier.janssens@batipro.be', '$2y$10$inoIwqt4GJSpI0zpDYwWTO129uYtGaBfcktuFWYJG4ByQq0QY96Y.', NULL),
(22, 'travailleur', 'Patrick Delvaux', '82.09.21-654.22', 'patrick.delvaux@batipro.be', '$2y$10$dqKGe6FP36tyJFgnNo/r8u1feujqV7yJGwNSZuTdGuZbgAuwJoGj6', NULL),
(23, 'travailleur', 'Eric Willems', '87.06.05-753.91', 'eric.willems@batipro.be', '$2y$10$i8KJLuaj/oY0wrIgBHFXze95Gsvxsf.ge/rz1xe2sxigqSKRjICCi', NULL),
(24, 'travailleur', 'François De Smet', '91.04.17-852.63', 'francois.desmet@batipro.be', '$2y$10$Govm7K2MSeUp5rRmA.QybutfKbuYfulbyNusom3kS2u7PWeThHTFG', NULL),
(25, 'travailleur', 'Yannick Leclercq', '89.03.19-951.74', 'yannick.leclercq@batipro.be', '$2y$10$Bl7aEdfmfHmaA7hNvpDhfuaQLY8z446yjDmdvterL5gVxg3YdGVIC', NULL),
(26, 'travailleur', 'Bruno Maes', '86.07.23-357.48', 'bruno.maes@batipro.be', '$2y$10$g/os7z39.9be0p6WG5AFge4r9l0i.FfjKTo8PMoaP1haObPWHdO36', NULL),
(27, 'travailleur', 'Damien Laurent', '93.10.08-159.26', 'damien.laurent@batipro.be', '$2y$10$1Uvd2g/PlEOSm222Zb2uy.gVvhLMxZ7m8rIcrfskG2nCLhizrea4K', NULL),
(28, 'travailleur', 'Romain Verbruggen', '88.05.14-468.52', 'romain.verbruggen@batipro.be', '$2y$10$5ufcGLPGQqp3SbVGczQIAett3.ZHzFRiqHSErziX5sPupCEmfK7IC', NULL),
(29, 'travailleur', 'Quentin Noel', '95.12.01-789.14', 'quentin.noel@batipro.be', '$2y$10$vhsKvZBtuz8XiXWQp2tdj.Yk1G1Dl90xD6vn7yXplA0BCtqZ5NslW', NULL),
(30, 'travailleur', 'Cedric Van Damme', '90.02.28-963.77', 'cedric.vandamme@batipro.be', '$2y$10$DxJSerxS4deVS8kfmpq4YuRDjNIfnJiB7voRy.LmGTCQpYXiU0PtG', NULL),
(31, 'travailleur', 'Loic Simonis', '87.08.13-147.69', 'loic.simonis@batipro.be', '$2y$10$Ys7lxOBlx/cNt3Yrc0oriOz82diqdfiaLG6mV/LcY5Mc1wojCFO5m', NULL),
(32, 'travailleur', 'Benjamin Pirard', '92.11.26-258.31', 'benjamin.pirard@batipro.be', '$2y$10$UctkjLudNIxvkGZw8yt/neDjqVjXubjf2t.jljz/ESrRJloBvNwI2', NULL),
(33, 'travailleur', 'Arnaud Gillet', '85.06.18-369.12', 'arnaud.gillet@batipro.be', '$2y$10$v2ntfQXN7ixvhw/2vIiIhOvFJ5M1c.V6IFwWoyDfxUIv5ygsSxezO', NULL),
(34, 'travailleur', 'Steve Marchal', '94.09.04-741.63', 'steve.marchal@batipro.be', '$2y$10$mbgD74g8Ee6yPVDh2YzdjeWsfdLw6PriK6/cTA7iRuqaRbd1OQn86', NULL),
(35, 'travailleur', 'Jordan Collet', '89.01.30-852.47', 'jordan.collet@batipro.be', '$2y$10$jJnqEBzYiaR4mpKtx/cbCOay1OfA5XnAQtqBj0MdnwZUi3eTMVNOu', NULL),
(1, 'contremaitre/manager', 'Pierre Dubois', '85.01.15-123.45', 'pierre.dubois@batipro.be', '$2y$10$I5oYqOhtMizGsecMZR35qO3rBfiEhwqXli6QM5wZMuilTWWMbSeee', NULL),
(3, 'contremaitre/manager', 'Michel Lambert', '82.06.22-456.78', 'michel.lambert@batipro.be', '$2y$10$bEpVkg7LfRaKGducy97vGuNUHX3d0f5zsP5HBZvQ6Ph1.BiJUFiI.', NULL),
(4, 'contremaitre/manager', 'Alain Dupont', '88.03.11-789.12', 'alain.dupont@batipro.be', '$2y$10$uM7keIImdLHfBTZ9Ud4tzeA9fo3wYIgXJ2gn1JTS7rkiRlARHag0C', NULL),
(5, 'contremaitre/manager', 'David Martin', '90.07.29-322.54', 'david.martin@batipro.be', '$2y$10$2aDzCEqcXIgumHZ7TEpk9eqHcds1sAfa14E6GlomCfUjk45lc3GRa', NULL),
(6, 'contremaitre/manager', 'Julien Leroy', '87.12.05-654.98', 'julien.leroy@batipro.be', '$2y$10$rzmBU6ZLtDY0oE5yf3KAR.KO9uiR7BaMTQz1U.BP36jL7ntqT4P6S', NULL),
(7, 'chef_equipe', 'Kevin Simon', '91.05.17-147.25', 'kevin.simon@batipro.be', '$2y$10$0iy.5ObfiwvzUtq8NFW80e9fuUggF3sfGFzrcpciI.o31OnNT2UMO', NULL),
(8, 'travailleur', 'Maxime Henry', '89.09.02-258.36', 'maxime.henry@batipro.be', '$2y$10$twkKhX2i5wilZMQQj277t.VgAM1fEX0dQeZb9ttNdquJ8E6WAelZW', NULL),
(9, 'travailleur', 'Antoine Willems', '86.11.08-369.47', 'antoine.willems@batipro.be', '$2y$10$4AbaNu7zVjt3VEZiFW200OZ0.dRyWA7neHJDE63JlskpjpSS7bIWC', NULL),
(10, 'travailleur', 'Samuel Maes', '92.02.24-741.58', 'samuel.maes@batipro.be', '$2y$10$YTNWJCf0wjQUXvQzQmOp7eC2su5Fmd22ylGG4hfoR9hhlkMRr1s52', NULL),
(11, 'travailleur', 'Vincent Noel', '84.08.13-852.69', 'vincent.noel@batipro.be', '$2y$10$VM9brvH5clVIGC3Fw3jvCel.fC/rGYutoM0R.h2o.2OaLmye/XfeW', NULL),
(12, 'travailleur', 'Benoit Laurent', '93.04.27-963.14', 'benoit.laurent@batipro.be', '$2y$10$hMCBve1Qo8UKXK9OfuvcYu4sSE06q0LzPCBVVlt03OcB86dFWnBke', NULL),
(37, 'travailleur', 'Guillaume Renard', '88.11.22-654.98', 'guillaume.renard@batipro.be', '$2y$10$xppvJ49bCO6CTnVafbhcQeM3bcxMz3XTG9aR9.73n0uq98c6grwru', NULL),
(36, 'travailleur', 'Adrien Fontaine', '91.05.14-321.47', 'adrien.fontaine@batipro.be', '$2y$10$FXDhi6GxZgLCZTnMQg1/5OPVzDwH6eXpjASUoNjDcWnXaTNQj/sVS', NULL),
(38, 'travailleur', 'Mathieu Denis', '86.03.08-741.52', 'mathieu.denis@batipro.be', '$2y$10$9eocLf43Pf924UGdT/TcEuWYA/bfLhgs/WjEPgy3vPmKuYAbpQxxa', NULL),
(39, 'travailleur', 'Cedric Hubert', '90.07.19-852.36', 'cedric.hubert@batipro.be', '$2y$10$p33KxeDVIm3Giwm8ET7AfOm7FGG3Q83YbBlh6r5JnXyI3Yl6N1I0O', NULL),
(40, 'chef_equipe', 'Pierre Collard', '87.02.15-963.74', 'pierre.collard@batipro.be', '$2y$10$wR8vMdOTdRdhUypKmZm3Q.LOnE2/bSeCair9mLDMWZYQZBDNq7lYe', NULL),
(41, 'contremaitre/manager', 'Thierry Moreau', '82.09.17-258.46', 'thierry.moreau@batipro.be', '$2y$10$XWgo/79QuzPcGMRt.54.I.afQET8F/6vj5N1sL8YkfXh2DN3.gxcG', NULL),
(42, 'contremaitre/manager', 'Laurent Evrard', '84.12.05-369.15', NULL, '', NULL),
(43, 'travailleur', 'Kevin Dumont', '93.04.11-147.83', 'kevin.dumont@batipro.be', '$2y$10$TVsfXkazxUmiYPqxYvz3cO6nbmkBf1qe0BviDdI6QEzErcAoKzLua', NULL),
(44, 'travailleur', 'Fabien Leroy', '89.08.29-741.96', 'fabien.leroy@batipro.be', '$2y$10$Yh77k6ACUvQAKG/.pZkbvu7Mbi9Ff9NOXT1ULqjiFFVLK9g/6TgGG', NULL),
(45, 'travailleur', 'Alexandre Hardy', '92.01.06-852.14', 'alexandre.hardy@batipro.be', '$2y$10$dZIYjZz/UgayxJXr3w/P.OtpFmi05uAiGUv931BPN/HApIQmY.VKG', NULL),
(46, 'travailleur', 'Sebastien Wauters', '90.04.22-741.36', NULL, '', NULL);

--
-- Triggers `travailleur`
--
DROP TRIGGER IF EXISTS `before_insert_travailleur_nrn`;
DELIMITER $$
CREATE TRIGGER `before_insert_travailleur_nrn` BEFORE INSERT ON `travailleur` FOR EACH ROW BEGIN

    IF NEW.no_registre_national REGEXP '^[0-9]{11}$' THEN

        SET NEW.no_registre_national =
            CONCAT(
                SUBSTRING(NEW.no_registre_national, 1, 2), '.',
                SUBSTRING(NEW.no_registre_national, 3, 2), '.',
                SUBSTRING(NEW.no_registre_national, 5, 2), '-',
                SUBSTRING(NEW.no_registre_national, 7, 3), '.',
                SUBSTRING(NEW.no_registre_national, 10, 2)
            );

    END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `before_update_travailleur_nrn`;
DELIMITER $$
CREATE TRIGGER `before_update_travailleur_nrn` BEFORE UPDATE ON `travailleur` FOR EACH ROW BEGIN

    IF NEW.no_registre_national REGEXP '^[0-9]{11}$' THEN

        SET NEW.no_registre_national =
            CONCAT(
                SUBSTRING(NEW.no_registre_national, 1, 2), '.',
                SUBSTRING(NEW.no_registre_national, 3, 2), '.',
                SUBSTRING(NEW.no_registre_national, 5, 2), '-',
                SUBSTRING(NEW.no_registre_national, 7, 3), '.',
                SUBSTRING(NEW.no_registre_national, 10, 2)
            );

    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `travailleur_equipe`
--

DROP TABLE IF EXISTS `travailleur_equipe`;
CREATE TABLE IF NOT EXISTS `travailleur_equipe` (
  `id_equipe` int NOT NULL,
  `id_travailleur` int NOT NULL,
  `role` enum('chef','employe') NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date DEFAULT NULL,
  PRIMARY KEY (`id_equipe`,`id_travailleur`),
  KEY `id_travailleur` (`id_travailleur`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `travailleur_equipe`
--

INSERT INTO `travailleur_equipe` (`id_equipe`, `id_travailleur`, `role`, `date_debut`, `date_fin`) VALUES
(1, 1, 'chef', '2025-01-01', '2026-06-17'),
(2, 2, 'chef', '2025-01-01', NULL),
(3, 3, 'chef', '2026-06-17', NULL),
(4, 4, 'chef', '2025-02-01', NULL),
(5, 5, 'chef', '2025-02-01', NULL),
(6, 6, 'chef', '2025-03-01', NULL),
(7, 13, 'chef', '2025-01-01', NULL),
(8, 14, 'chef', '2025-01-01', NULL),
(9, 15, 'chef', '2025-01-01', NULL),
(10, 16, 'chef', '2025-02-01', NULL),
(11, 41, 'chef', '2025-07-01', NULL),
(12, 18, 'chef', '2025-03-01', NULL),
(13, 19, 'chef', '2025-03-01', NULL),
(14, 20, 'chef', '2025-04-01', NULL),
(29, 7, 'chef', '2026-06-16', NULL),
(30, 6, 'chef', '2026-06-16', NULL),
(31, 7, 'chef', '2026-06-16', NULL),
(1, 4, 'employe', '2025-01-01', NULL),
(1, 7, 'employe', '2025-01-01', NULL),
(1, 8, 'employe', '2025-01-01', NULL),
(2, 5, 'employe', '2025-01-01', NULL),
(2, 9, 'employe', '2025-01-01', NULL),
(2, 10, 'employe', '2025-01-01', NULL),
(3, 11, 'employe', '2025-01-01', NULL),
(3, 12, 'employe', '2025-01-01', NULL),
(4, 1, 'employe', '2025-02-01', NULL),
(4, 8, 'employe', '2025-02-01', NULL),
(5, 2, 'employe', '2025-02-01', NULL),
(5, 10, 'employe', '2025-02-01', NULL),
(6, 3, 'employe', '2025-03-01', NULL),
(6, 7, 'employe', '2025-03-01', NULL),
(6, 9, 'employe', '2025-03-01', NULL),
(7, 14, 'employe', '2025-01-01', NULL),
(7, 15, 'employe', '2025-01-01', NULL),
(7, 16, 'employe', '2025-01-01', NULL),
(8, 17, 'employe', '2025-01-01', NULL),
(8, 18, 'employe', '2025-01-01', NULL),
(8, 19, 'employe', '2025-01-01', NULL),
(9, 20, 'employe', '2025-01-01', NULL),
(9, 21, 'employe', '2025-01-01', NULL),
(9, 22, 'employe', '2025-01-01', NULL),
(10, 14, 'employe', '2025-02-01', NULL),
(10, 19, 'employe', '2025-02-01', NULL),
(11, 17, 'employe', '2025-02-01', NULL),
(11, 13, 'employe', '2025-02-01', NULL),
(11, 18, 'employe', '2025-02-01', NULL),
(12, 20, 'employe', '2025-03-01', NULL),
(12, 21, 'employe', '2025-03-01', NULL),
(13, 22, 'employe', '2025-03-01', NULL),
(13, 23, 'employe', '2025-03-01', NULL),
(14, 15, 'employe', '2025-04-01', NULL),
(14, 24, 'employe', '2025-04-01', NULL),
(14, 25, 'employe', '2025-04-01', NULL),
(8, 36, 'employe', '2025-07-01', NULL),
(8, 37, 'employe', '2025-07-01', NULL),
(9, 38, 'employe', '2025-07-01', NULL),
(9, 39, 'employe', '2025-07-01', NULL),
(10, 40, 'employe', '2025-07-01', NULL),
(11, 42, 'employe', '2025-07-01', '2026-06-18'),
(12, 43, 'employe', '2025-07-01', NULL),
(12, 44, 'employe', '2025-07-01', NULL),
(13, 45, 'employe', '2025-07-01', NULL),
(29, 12, 'employe', '2026-06-09', NULL),
(29, 16, 'employe', '2026-06-09', NULL),
(29, 14, 'employe', '2026-06-09', NULL),
(29, 18, 'employe', '2026-06-09', NULL),
(29, 13, 'employe', '2026-06-09', NULL),
(30, 42, 'employe', '2026-06-09', '2026-06-18'),
(30, 43, 'employe', '2026-06-09', NULL),
(30, 13, 'employe', '2026-06-09', NULL),
(30, 44, 'employe', '2026-06-09', NULL),
(31, 43, 'employe', '2026-06-09', NULL),
(31, 6, 'employe', '2026-06-09', NULL),
(31, 5, 'employe', '2026-06-09', NULL),
(31, 44, 'employe', '2026-06-09', NULL),
(9, 31, 'employe', '2025-09-01', NULL),
(6, 26, 'employe', '2026-01-15', NULL),
(2, 27, 'employe', '2026-02-01', NULL),
(7, 30, 'employe', '2026-02-01', NULL),
(3, 32, 'employe', '2026-03-01', NULL),
(12, 33, 'employe', '2026-03-01', NULL),
(1, 34, 'employe', '2026-04-01', NULL),
(13, 35, 'employe', '2026-04-01', NULL),
(2, 36, 'employe', '2025-01-15', '2025-06-30'),
(32, 42, 'chef', '2025-09-01', '2026-03-31'),
(32, 28, 'employe', '2025-09-01', '2026-03-31'),
(32, 29, 'employe', '2025-09-01', '2026-03-31'),
(33, 40, 'chef', '2026-06-16', NULL),
(2, 46, 'employe', '2026-01-01', '2026-06-16'),
(1, 2, 'chef', '2026-06-17', NULL),
(3, 4, 'chef', '2026-06-17', '2026-06-17'),
(3, 5, 'employe', '2026-06-17', NULL),
(34, 1, 'chef', '2026-06-19', '2026-06-19'),
(34, 3, 'employe', '2026-06-19', '2026-06-19'),
(34, 5, 'employe', '2026-06-19', '2026-06-19'),
(34, 4, 'employe', '2026-06-19', '2026-06-19');

-- --------------------------------------------------------

--
-- Table structure for table `type_contrat`
--

DROP TABLE IF EXISTS `type_contrat`;
CREATE TABLE IF NOT EXISTS `type_contrat` (
  `id_travailleur` int NOT NULL,
  `id_contrat` bigint NOT NULL AUTO_INCREMENT,
  `type_contrat` enum('mi-temps','1/3 temps','2/3 temps','1/4 temps','3/4 temps','1/5 temps','2/5 temps','3/5 temps','4/5 temps','3/10 temps','7/10 temps','9/10 temps','temps plein') NOT NULL,
  `heures_journee_travail` enum('7.6','8') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `date_debut` date NOT NULL,
  `date_fin` date DEFAULT NULL,
  PRIMARY KEY (`id_contrat`),
  KEY `id_travailleur` (`id_travailleur`)
) ENGINE=MyISAM AUTO_INCREMENT=50 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `type_contrat`
--

INSERT INTO `type_contrat` (`id_travailleur`, `id_contrat`, `type_contrat`, `heures_journee_travail`, `date_debut`, `date_fin`) VALUES
(1, 1, 'temps plein', '8', '2025-01-01', NULL),
(2, 2, 'temps plein', '8', '2025-01-01', NULL),
(3, 3, 'temps plein', '8', '2025-01-01', NULL),
(4, 4, 'temps plein', '8', '2025-02-01', NULL),
(5, 5, 'temps plein', '8', '2025-02-01', NULL),
(6, 6, 'temps plein', '8', '2025-03-01', NULL),
(7, 7, '4/5 temps', '8', '2025-01-01', NULL),
(8, 8, 'mi-temps', '8', '2025-01-15', NULL),
(9, 9, '2/3 temps', '7.6', '2025-02-01', NULL),
(10, 10, 'temps plein', '8', '2025-01-01', NULL),
(11, 11, '1/3 temps', '7.6', '2025-01-01', NULL),
(12, 12, '3/5 temps', '7.6', '2025-03-01', NULL),
(13, 13, 'temps plein', '8', '2025-01-01', NULL),
(14, 14, '9/10 temps', '8', '2025-01-01', NULL),
(15, 15, 'temps plein', '8', '2025-01-01', NULL),
(16, 16, '7/10 temps', '7.6', '2025-02-01', NULL),
(17, 17, 'temps plein', '8', '2025-03-01', NULL),
(18, 18, '4/5 temps', '8', '2025-01-15', NULL),
(19, 19, 'temps plein', '8', '2025-02-15', NULL),
(20, 20, '9/10 temps', '8', '2025-02-15', NULL),
(21, 21, 'temps plein', '8', '2025-01-01', NULL),
(22, 22, '2/5 temps', '7.6', '2025-02-01', NULL),
(23, 23, 'mi-temps', '8', '2025-01-15', NULL),
(24, 24, 'temps plein', '8', '2025-01-01', NULL),
(25, 25, '1/4 temps', '7.6', '2025-04-01', NULL),
(26, 26, 'temps plein', '8', '2025-01-01', NULL),
(27, 27, '7/10 temps', '7.6', '2025-03-01', NULL),
(28, 28, 'mi-temps', '8', '2025-02-01', NULL),
(29, 29, 'temps plein', '8', '2025-01-01', NULL),
(30, 30, '2/3 temps', '7.6', '2025-03-15', NULL),
(31, 31, 'temps plein', '8', '2025-01-01', NULL),
(32, 32, '3/10 temps', '7.6', '2025-04-01', NULL),
(33, 33, 'temps plein', '8', '2025-01-01', NULL),
(34, 34, '4/5 temps', '8', '2025-02-01', NULL),
(35, 35, '3/5 temps', '7.6', '2025-01-01', NULL),
(36, 36, 'temps plein', '8', '2025-03-01', NULL),
(37, 37, 'mi-temps', '8', '2025-03-15', NULL),
(38, 38, 'temps plein', '8', '2025-02-01', NULL),
(39, 39, '1/3 temps', '7.6', '2025-01-15', NULL),
(40, 40, 'temps plein', '8', '2025-01-01', NULL),
(41, 41, 'temps plein', '8', '2025-01-01', NULL),
(42, 42, '9/10 temps', '8', '2025-01-01', '2026-06-18'),
(43, 43, '4/5 temps', '8', '2025-04-01', NULL),
(44, 44, 'temps plein', '8', '2025-02-01', NULL),
(45, 45, '2/5 temps', '7.6', '2025-03-01', NULL),
(24, 46, '1/5 temps', '7.6', '2024-06-01', '2024-12-31'),
(31, 47, '3/4 temps', '7.6', '2024-09-01', '2024-12-31'),
(46, 48, 'mi-temps', '8', '2026-01-01', '2026-06-16');
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
