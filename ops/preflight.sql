SELECT current_user, current_database();
SELECT ssl,version,cipher FROM pg_stat_ssl WHERE pid=pg_backend_pid();
DO $$ BEGIN
 IF current_user <> 'homebox_app' THEN RAISE EXCEPTION 'Rol incorrecto'; END IF;
 IF current_setting('server_version_num')::int NOT BETWEEN 160000 AND 179999 THEN RAISE EXCEPTION 'Preparado para PG16/17'; END IF;
 IF NOT has_schema_privilege(current_user,'public','CREATE') THEN RAISE EXCEPTION 'Sin CREATE'; END IF;
END $$;
