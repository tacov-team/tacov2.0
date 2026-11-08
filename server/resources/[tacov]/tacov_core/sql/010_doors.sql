-- TacoV Kern · Migration 010 · Door Creator (Punkt 5.4)
CREATE TABLE IF NOT EXISTS doors (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(64) NOT NULL DEFAULT '',
  parts TEXT NOT NULL,                 -- JSON: [{ model, x, y, z }]
  access TEXT NULL,                    -- JSON: { faction, minRank, item, team }
  locked TINYINT(1) NOT NULL DEFAULT 1,
  auto_close INT UNSIGNED NOT NULL DEFAULT 0,   -- Sekunden, 0 = nie
  updated_by VARCHAR(32) NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
