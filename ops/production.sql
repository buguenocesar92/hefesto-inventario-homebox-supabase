DO $$ BEGIN
 IF to_regclass('public.users') IS NULL THEN RAISE EXCEPTION 'Inicializar mediante bootstrap privado'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.users) THEN RAISE EXCEPTION 'Crear primera cuenta en bootstrap'; END IF;
END $$;
