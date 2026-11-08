-- TacoV Kern · Migration 009 · Orte-Creator (Punkt 5.3): Zusatzfelder und Ausblenden von Config-Orten
ALTER TABLE locations ADD COLUMN IF NOT EXISTS extra TEXT NULL;
ALTER TABLE locations ADD COLUMN IF NOT EXISTS disabled TINYINT(1) NOT NULL DEFAULT 0;
