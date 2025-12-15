-- Ejemplo de inicialización para stack01
-- Crea una tabla de ejemplo y añade filas iniciales

CREATE TABLE IF NOT EXISTS example (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

INSERT INTO example (name) VALUES ('alpha') ON CONFLICT DO NOTHING;
INSERT INTO example (name) VALUES ('bravo') ON CONFLICT DO NOTHING;
