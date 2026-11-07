-- TacoV Kern · Migration 003 · Fahrzeuge
-- state: garage (steht in `garage`), out (unterwegs), impound (verwahrt)

CREATE TABLE IF NOT EXISTS vehicles (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  plate VARCHAR(8) NOT NULL UNIQUE,
  model VARCHAR(32) NOT NULL,
  class VARCHAR(8) NOT NULL,
  owner_type ENUM('character','faction','business') NOT NULL DEFAULT 'character',
  owner_id INT UNSIGNED NOT NULL,
  state ENUM('garage','out','impound') NOT NULL DEFAULT 'garage',
  garage VARCHAR(48) NULL,
  fuel FLOAT NOT NULL DEFAULT 0,
  mileage_km FLOAT NOT NULL DEFAULT 0,
  body_health FLOAT NOT NULL DEFAULT 1000,
  engine_health FLOAT NOT NULL DEFAULT 1000,
  props JSON NULL,
  parked_at TIMESTAMP NULL DEFAULT NULL,
  last_seen_at TIMESTAMP NULL DEFAULT NULL,
  bought_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  bought_price INT UNSIGNED NOT NULL DEFAULT 0,
  deleted_at TIMESTAMP NULL DEFAULT NULL,
  INDEX idx_vehicles_owner (owner_type, owner_id),
  INDEX idx_vehicles_state (state)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Schlüssel: wer ein Fahrzeug auf- und zuschließen, fahren, einparken darf (Halter hat immer einen)
CREATE TABLE IF NOT EXISTS vehicle_keys (
  vehicle_id INT UNSIGNED NOT NULL,
  character_id INT UNSIGNED NOT NULL,
  given_by INT UNSIGNED NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (vehicle_id, character_id),
  CONSTRAINT fk_vehicle_keys_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE,
  CONSTRAINT fk_vehicle_keys_character FOREIGN KEY (character_id) REFERENCES characters(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
