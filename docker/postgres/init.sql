-- Runtime role for the API. Not a superuser and cannot bypass row-level security.
-- The password is for local development and tests only.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'lukas_app') THEN
    CREATE ROLE lukas_app LOGIN PASSWORD 'lukas_app' NOSUPERUSER NOBYPASSRLS;
  END IF;
END
$$;
GRANT USAGE ON SCHEMA public TO lukas_app;
