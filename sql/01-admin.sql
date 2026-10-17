-- Solo en proyecto Supabase exclusivo con public vacio. Reemplazar clave.
CREATE ROLE homebox_app LOGIN PASSWORD 'REEMPLAZAR_CON_CLAVE_ALEATORIA';
GRANT CONNECT ON DATABASE postgres TO homebox_app;
GRANT USAGE,CREATE ON SCHEMA public TO homebox_app;
-- No usar superusuario, postgres ni service_role en la aplicacion.
