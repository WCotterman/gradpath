﻿/**
	SHOW TABLES;
  
	CREATE USER 'sec_user'@'localhost' IDENTIFIED BY 'eKcGZr59zAa2BEWU';
	GRANT SELECT, INSERT, UPDATE ON `secure_login`.* TO 'sec_user'@'localhost';
	FLUSH PRIVILEGES;
	DROP USER ‘sec_user’@‘localhost’;

	Populate w/:
		Initial accounts.
		Campuses. (Add ONLINE)
		Buildings. (Add ONLINE)
		Classrooms. (Add ONLINE)
		Degrees.
		Courses.
		Course prequisites.
		Degree requirements.
		Classes previously offered and upcoming.
		Class meeting times.

	If incoming student doesn't have any background, faculty can fill out courses already taken/passed.
	Need to be able to plot out previously taken classes.
*/

/*
SET FOREIGN_KEY_CHECKS = 0;
SET GROUP_CONCAT_MAX_LEN=32768;
SET @tables = NULL;
SELECT GROUP_CONCAT('`', table_name, '`') INTO @tables
  FROM information_schema.tables
  WHERE table_schema = (SELECT DATABASE());
SELECT IFNULL(@tables,'dummy') INTO @tables;

SET @tables = CONCAT('DROP TABLE IF EXISTS ', @tables);
PREPARE stmt FROM @tables;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
SET FOREIGN_KEY_CHECKS = 1;

DROP TABLE `account_class_history`;
DROP TABLE `degree_requirement`;
DROP TABLE `class_meeting_time`;
DROP TABLE `course_class`;
DROP TABLE `course_prerequisite`;
DROP TABLE `course`;
DROP TABLE `department`;
DROP TABLE `degree`;
DROP TABLE `classroom`;
DROP TABLE `building`;
DROP TABLE `campus`;
DROP TABLE `graduation_path_search`;
DROP TABLE `account`;
*/

CREATE TABLE `account` (
	`id` INT AUTO_INCREMENT NOT NULL,
	`username` VARCHAR(50) NOT NULL,
	`password` CHAR(128) NOT NULL,
	`first_name` VARCHAR(50) NOT NULL,
	`last_name` VARCHAR(50) NOT NULL,
	`role` VARCHAR(10) NOT NULL, /*[STUDENT, FACULTY, ADMIN]*/
	PRIMARY KEY (`id`)
) ENGINE = InnoDB;

CREATE TABLE `graduation_path_search` (
    `id` INT AUTO_INCREMENT NOT NULL,
	`option` VARCHAR(50) NOT NULL, /*[DEGREE, CONCENTRATION, ENTERING_QUARTER, COURSES_PER_QUARTER, DELIVERY_METHOD]*/
	`value` VARCHAR(1000),
    `account_id` INT NOT NULL,
	PRIMARY KEY (`id`, `option`),
	/*FOREIGN KEY (`username`) REFERENCES `account`(`username`)*/
	CONSTRAINT `fk_account_path_search_account`
	FOREIGN KEY (`account_id`)
	REFERENCES `account`(`id`)
) ENGINE = InnoDB;

CREATE TABLE `campus` (
	`name` VARCHAR(20) NOT NULL,
	PRIMARY KEY (`name`)
) ENGINE = InnoDB;

CREATE TABLE `building` (
	`campus_name` VARCHAR(20) NOT NULL,
	`name` VARCHAR(20) NOT NULL,
	`address` VARCHAR(200),
	PRIMARY KEY (`campus_name`, `name`),
	CONSTRAINT `fk_building_campus`
	FOREIGN KEY (`campus_name`)
	REFERENCES `campus`(`name`)
) ENGINE = InnoDB;

CREATE TABLE `classroom` (
	`id` INT AUTO_INCREMENT NOT NULL,
    `campus_name` VARCHAR(20) NOT NULL,
	`building_name` VARCHAR(20) NOT NULL,
	`number` INT NOT NULL,
	`section` CHAR(10),
	PRIMARY KEY (`id`),
	CONSTRAINT `fk_classroom_building_name`
	FOREIGN KEY (`campus_name`, `building_name`)
	REFERENCES `building`(`campus_name`, `name`)
) ENGINE = InnoDB;

CREATE TABLE `degree` (
	`name` VARCHAR(20) NOT NULL,
	`title` VARCHAR(20),
	`college` VARCHAR(20),
	`concentration` CHAR(5), /*[BA, MS, MBA, etc.]*/
	`description` VARCHAR(1000),
	PRIMARY KEY (`name`)
) ENGINE = InnoDB;

CREATE TABLE `department` (
	`code` CHAR(3) NOT NULL,
	`title` VARCHAR(50),
	`description` VARCHAR(1000),
	PRIMARY KEY (`code`)
) ENGINE = InnoDB;

CREATE TABLE `course` (
	`id` INT AUTO_INCREMENT NOT NULL,
	`number` INT NOT NULL,
	`department_code` CHAR(3) NOT NULL,
	`people_soft_number` INT, /*?*/
	`title` VARCHAR(50),
	`description` VARCHAR(1000),
	`units` DECIMAL(3,2) DEFAULT '4.00',
	`status` CHAR(10) DEFAULT 'ACTIVE', /*[ACTIVE, DORMANT (no activity in last 2 years)], might just be in logic to check?*/
	PRIMARY KEY (`id`),
    CONSTRAINT `fk_course_department`
	FOREIGN KEY (`department_code`)
	REFERENCES `department`(`code`)
) ENGINE = InnoDB;

CREATE TABLE `course_prerequisite` (
	`course_id` INT NOT NULL,
	`id` INT NOT NULL,
	PRIMARY KEY (`course_id`, `id`),
	CONSTRAINT `fk_course_prerequisite_course`
	FOREIGN KEY (`course_id`)
	REFERENCES `course`(`id`)
) ENGINE = InnoDB;

CREATE TABLE `course_class` (
	`id` INT AUTO_INCREMENT NOT NULL,
	`section_number` CHAR(5),
	`course_id` INT NOT NULL,
	`date_start` DATE,
	`date_end` DATE,
	`status` VARCHAR(10), /*[OPEN, WAIT_LIST etc.]*/
	`classroom_id` INT,
	`instructor_account_id` INT NOT NULL,
	PRIMARY KEY (`id`),
	CONSTRAINT `fk_class_course`
	FOREIGN KEY (`course_id`)
	REFERENCES `course`(`id`),
    CONSTRAINT `fk_class_classroom`
	FOREIGN KEY (`classroom_id`)
	REFERENCES `classroom`(`id`),
	CONSTRAINT `fk_class_account_instructor`
	FOREIGN KEY (`instructor_account_id`)
	REFERENCES `account`(`id`)
) ENGINE = InnoDB;

CREATE TABLE `class_meeting_time` (
	`class_id` INT NOT NULL,
	`day_of_week` CHAR(2),
	`time_of_day_begin` TIME,
	`time_of_day_end` TIME,
	PRIMARY KEY (`class_id`, `day_of_week`),
	CONSTRAINT `fk_class_meeting_time_class`
	FOREIGN KEY (`class_id`)
	REFERENCES `course_class`(`id`)
) ENGINE = InnoDB;

CREATE TABLE `degree_requirement` (
	`degree_name` VARCHAR(20) NOT NULL,
	`course_id` INT,
	`status` CHAR(10) NOT NULL DEFAULT 'REQUIRED',
	`elective_department_code` CHAR(3),
	PRIMARY KEY (`degree_name`, `course_id`),
    CONSTRAINT `fk_degree_requirement_degree`
	FOREIGN KEY (`degree_name`)
	REFERENCES `degree`(`name`),
	CONSTRAINT `fk_degree_requirement_course`
	FOREIGN KEY (`course_id`)
	REFERENCES `course`(`id`),
	FOREIGN KEY (`elective_department_code`) REFERENCES `department`(`code`)
) ENGINE = InnoDB;

CREATE TABLE `account_class_history` (
	`account_id` INT NOT NULL,
	`class_id` INT NOT NULL,
    `grade` CHAR(5),
	PRIMARY KEY (`account_id`, `class_id`),
	CONSTRAINT `fk_class_history_class`
	FOREIGN KEY (`class_id`)
	REFERENCES `course_class`(`id`)
) ENGINE = InnoDB;