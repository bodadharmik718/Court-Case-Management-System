-- Add demo authentication to a coursework database created before this update.
-- All seeded accounts receive the local-only password CourtAccess@2026.
-- Change passwords before using this database outside a local lab environment.
ALTER TABLE public.app_user
    ADD COLUMN IF NOT EXISTS password_hash TEXT;

UPDATE public.app_user
SET password_hash = '$argon2id$v=19$m=19456,t=2,p=1$onipBZEWYfzmsGbqbBFEVw$5xKF8AcJK5nXDVsX+AQaZ0j+Ni9ppt7An84fD/oicio'
WHERE password_hash IS NULL;

ALTER TABLE public.app_user
    ALTER COLUMN password_hash SET NOT NULL,
    ALTER COLUMN password_hash SET DEFAULT '$argon2id$v=19$m=19456,t=2,p=1$onipBZEWYfzmsGbqbBFEVw$5xKF8AcJK5nXDVsX+AQaZ0j+Ni9ppt7An84fD/oicio';
