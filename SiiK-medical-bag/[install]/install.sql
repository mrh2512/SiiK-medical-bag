CREATE TABLE IF NOT EXISTS `siik_medical_bags` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `stash_id` VARCHAR(64) NOT NULL,
  `owner_cid` VARCHAR(64) NOT NULL,
  `x` DOUBLE NOT NULL DEFAULT 0,
  `y` DOUBLE NOT NULL DEFAULT 0,
  `z` DOUBLE NOT NULL DEFAULT 0,
  `h` DOUBLE NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_stash_id` (`stash_id`),
  KEY `idx_owner_cid` (`owner_cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

