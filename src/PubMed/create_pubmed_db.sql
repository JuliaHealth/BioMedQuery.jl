CREATE TABLE IF NOT EXISTS `basic` (
      `pmid` int(9) NOT NULL,
      `pub_year` smallint(4) DEFAULT NULL,
      `pub_month` tinyint(2) DEFAULT NULL,
      `pub_dt_desc` varchar(50) DEFAULT NULL,
      `title` text DEFAULT NULL,
      `authors` text DEFAULT NULL,
      `journal_title` varchar(500) DEFAULT NULL,
      `journal_ISSN` varchar(9) DEFAULT NULL,
      `journal_volume` varchar(30) DEFAULT NULL,
      `journal_issue` varchar(30) DEFAULT NULL,
      `journal_pages` varchar(50) DEFAULT NULL,
      `journal_iso_abbreviation` varchar(255) DEFAULT NULL,
      `url` varchar(100) DEFAULT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`pmid`),
      KEY `pub_year` (`pub_year`),
      KEY `pub_month` (`pub_month`),
      KEY `pub_year_month` (`pub_year`,`pub_month`),
      KEY `journal_title` (`journal_title`),
      KEY `journal_ISSN` (`journal_ISSN`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE `author_ref` (
      `pmid` int(10) NOT NULL,
      `last_name` varchar(60) DEFAULT NULL,
      `first_name` varchar(60) DEFAULT NULL,
      `initials` varchar(10) DEFAULT NULL,
      `suffix` varchar(10) DEFAULT NULL,
      `orcid` varchar(19) DEFAULT NULL,
      `collective` varchar(200) DEFAULT NULL,
      `affiliation` varchar(255) DEFAULT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      KEY `last_name` (`last_name`),
      KEY `last_first_name` (`last_name`, `first_name`),
      KEY `collective` (`collective`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `author2article` (
       `pmid` int(9) NOT NULL,
       `author_id` int(10) NOT NULL,
       `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
       PRIMARY KEY (`pmid`, `author_id`),
       FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
       FOREIGN KEY(`author_id`) REFERENCES author_ref(`author_id`)
     ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `pub_type` (
      `pmid` int(9) NOT NULL,
      `uid` int(6) NOT NULL,
      `name` varchar(100) NOT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`pmid`,`uid`),
      KEY `name` (`name`),
      FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `abstract_full` (
      `pmid` int(9) NOT NULL,
      `abstract_text` text DEFAULT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`pmid`),
      FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `abstract_structured` (
      `abstracts_structured_id` int(12) NOT NULL AUTO_INCREMENT,
      `pmid` int(9) NOT NULL,
      `nlm_category` varchar(20) DEFAULT NULL,
      `label` varchar(40) DEFAULT NULL,
      `abstract_text` text DEFAULT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`abstracts_structured_id`, `pmid`),
      FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
      KEY `label` (`label`),
      KEY `nlm_category` (`nlm_category`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `file_meta` (
      `file_name` varchar(30) NOT NULL,
      `ins_start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `ins_end_time` timestamp NULL,
      PRIMARY KEY (`file_name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


CREATE TABLE IF NOT EXISTS `mesh_desc` (
      `uid` int(6) NOT NULL,
      `name` varchar(100) NOT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`uid`),
      KEY `name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE `mesh_qual` (
      `uid` int(6) NOT NULL,
      `name` varchar(100) NOT NULL,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`uid`),
      KEY `name` (`name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `mesh_heading` (
      `pmid` int(9) NOT NULL,
      `desc_uid` int(6) NOT NULL,
      `desc_maj_status` boolean DEFAULT NULL,
      `qual_uid` int(6) DEFAULT -1,
      `qual_maj_status` boolean DEFAULT -1,
      `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (`pmid`, `desc_uid`, `qual_uid`),
      FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
      FOREIGN KEY(`desc_uid`) REFERENCES mesh_desc(`uid`),
      KEY `desc_uid_maj` (`desc_uid`,`desc_maj_status`),
      FOREIGN KEY(`qual_uid`) REFERENCES mesh_qual(`uid`),
      KEY `qual_UID_maj` (`qual_UID`,`qual_maj_status`)
    ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
