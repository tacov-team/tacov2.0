-- TacoV Kern · Migration 012 · NPC-Creator (Punkt 5.7)
CREATE TABLE IF NOT EXISTS peds (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(64) NOT NULL DEFAULT '',
  model VARCHAR(48) NOT NULL,
  x DOUBLE NOT NULL, y DOUBLE NOT NULL, z DOUBLE NOT NULL, h DOUBLE NOT NULL DEFAULT 0,
  scenario VARCHAR(64) NULL,
  task VARCHAR(24) NULL,               -- Aufforderung, die der NPC auslöst (shop, bank, dealer, dmv, garage, workshop, fuel)
  updated_by VARCHAR(32) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
