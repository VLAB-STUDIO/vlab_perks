CREATE TABLE IF NOT EXISTS `vlab_perks` (
  `steam` varchar(50) NOT NULL,
  `charId` int(11) NOT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `exp` decimal(12,2) NOT NULL DEFAULT 0.00,
  `point` int(11) NOT NULL DEFAULT 0,
  `slippery_bastard` tinyint(1) NOT NULL DEFAULT 0,
  `a_moment_to_recuperate` tinyint(1) NOT NULL DEFAULT 0,
  `quite_an_inspiration` tinyint(1) NOT NULL DEFAULT 0,
  `sharpshooter` tinyint(1) NOT NULL DEFAULT 0,
  `strange_medicine` tinyint(1) NOT NULL DEFAULT 0,
  `the_unblinking_eye` tinyint(1) NOT NULL DEFAULT 0,
  `gunslingers_choice` tinyint(1) NOT NULL DEFAULT 0,
  `take_the_pain_away` tinyint(1) NOT NULL DEFAULT 0,
  `redeem` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`steam`,`charId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;