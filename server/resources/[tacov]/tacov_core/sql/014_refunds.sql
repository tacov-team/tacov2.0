-- TacoV Kern · Migration 014 · Erstattungen mit Vier-Augen-Prinzip (Punkt 5.11)
CREATE TABLE IF NOT EXISTS refunds (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  character_id INT UNSIGNED NOT NULL,
  kind VARCHAR(8) NOT NULL,            -- money | item
  amount INT UNSIGNED NOT NULL DEFAULT 0,
  item VARCHAR(48) NULL,
  reason VARCHAR(255) NOT NULL,
  status VARCHAR(10) NOT NULL DEFAULT 'open',   -- open | paid | rejected
  requested_by VARCHAR(32) NOT NULL,
  decided_by VARCHAR(32) NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  decided_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_refunds_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
