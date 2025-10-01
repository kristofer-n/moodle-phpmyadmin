-- phpMyAdmin SQL Dump (parandatud ja täiendatud)
-- versioon: 5.2.1
-- MariaDB 10.4.32

SET FOREIGN_KEY_CHECKS=0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

CREATE DATABASE IF NOT EXISTS `moodle`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `moodle`;

-- --------------------------------------------------------
-- Users
-- --------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(50) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_username` (`username`),
  UNIQUE KEY `uniq_email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Courses
-- --------------------------------------------------------
DROP TABLE IF EXISTS `courses`;
CREATE TABLE `courses` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(100) NOT NULL,
  `description` MEDIUMTEXT NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Course attachments (iga kursuse fail eraldi real)
-- --------------------------------------------------------
DROP TABLE IF EXISTS `course_attachments`;
CREATE TABLE `course_attachments` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `course_id` INT UNSIGNED NOT NULL,
  `file_name` VARCHAR(255) NOT NULL,
  `file_data` LONGBLOB NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_attachment_course` (`course_id`),
  CONSTRAINT `fk_attachment_course`
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- User ↔ Course seosed
-- --------------------------------------------------------
DROP TABLE IF EXISTS `user_courses`;
CREATE TABLE `user_courses` (
  `user_id` INT UNSIGNED NOT NULL,
  `course_id` INT UNSIGNED NOT NULL,
  `grade` VARCHAR(2) NULL,
  PRIMARY KEY (`user_id`, `course_id`),
  CONSTRAINT `chk_grade_valid`
    CHECK (`grade` IS NULL OR `grade` IN ('2','3','4','5','A','MA')),
  CONSTRAINT `fk_usercourses_user`
    FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
    ON DELETE CASCADE,
  CONSTRAINT `fk_usercourses_course`
    FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`)
    ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Indeksid JOIN / WHERE tingimuste jaoks
-- --------------------------------------------------------
CREATE INDEX idx_usercourses_user_id ON user_courses(user_id);
CREATE INDEX idx_usercourses_course_id ON user_courses(course_id);
CREATE INDEX idx_attachments_course_id ON course_attachments(course_id);

SET FOREIGN_KEY_CHECKS=1;
COMMIT;
