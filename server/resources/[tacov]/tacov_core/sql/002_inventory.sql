-- TacoV Kern · Migration 002 · Inventar
-- Ein Platz je Zeile. owner_type: character, vehicle, stash, house, business, faction

CREATE TABLE IF NOT EXISTS inventory_items (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  owner_type VARCHAR(16) NOT NULL,
  owner_id INT UNSIGNED NOT NULL,
  slot SMALLINT UNSIGNED NOT NULL,
  item VARCHAR(48) NOT NULL,
  amount INT UNSIGNED NOT NULL DEFAULT 1,
  meta JSON NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_inventory_slot (owner_type, owner_id, slot),
  INDEX idx_inventory_item (item)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
