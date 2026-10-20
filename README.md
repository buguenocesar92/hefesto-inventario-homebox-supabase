# Hefesto Inventario · Homebox 0.26.2 + Supabase
Kit de despliegue de Homebox para inventariar equipos y objetos, organizar ubicaciones, conservar fotos y documentos y registrar datos de compra/garantía. Utiliza la aplicación original; no contiene una interfaz de demostración que simule operaciones.

## Stack
Homebox oficial rootless fijado por digest, PostgreSQL Supabase con TLS verify-full y CA, volumen local /data para archivos. No utiliza Supabase Auth, Storage ni Realtime. No añade Odoo, n8n, SMTP u otros servicios sin configurar.

## Incluye
Compose para Coolify, inicialización privada, registro cerrado en operación normal, rol SQL exclusivo, comprobación previa, respaldo/restauración y plantillas de trabajo. El CSV es una plantilla para carga manual, no se anuncia como importador nativo compatible.

## Arranque
1. Leer docs/INSTALACION.md. Preparar proyecto Supabase dedicado con PG16/17 y public vacío.
2. `python3 scripts/configure.py`. Editar .env: URL HTTPS, host directo Supabase y clave del rol. Copiar CA como certs/ca.crt.
3. Ejecutar sql/01-admin.sql como administrador, reemplazando la clave por la misma del .env. Usar clave aleatoria alfanumérica de al menos 32 caracteres.
4. `docker compose config --quiet`
5. Crear primera cuenta usando exclusivamente el bootstrap privado por SSH indicado en la guía.
6. Retirar bootstrap, configurar dominio HTTPS en Coolify apuntando a app:7745 e iniciar compose.yaml.
7. Completar docs/ACEPTACION.md antes de vender o entregar la instalación.

No hay secretos reales, cuentas creadas ni conexión activa incluidos. El paquete es un kit de despliegue; el código original se obtiene mediante la imagen Docker fijada, no se incluye completo en el ZIP.

## Despliegue en Coolify (MVP Hefesto)

El `compose.yaml` está pensado para Coolify build pack Docker Compose detrás de Traefik (TLS y dominio los pone Coolify):

- Sin `ports:` ni `name:` raíz fijo; Coolify asigna el nombre del proyecto y enruta el dominio al servicio `app` en el puerto interno `7745`.
- Variables de base parametrizadas con defaults que conservan el uso original; ajusta solo lo que necesites:

  | Variable | Default | Para qué |
  | --- | --- | --- |
  | `DB_HOST` | (obligatoria) | Host del proyecto Supabase dedicado (conexión directa 5432). |
  | `DB_PASSWORD` | (obligatoria) | Contraseña del rol `homebox_app` creado con `sql/01-admin.sql`. |
  | `APP_URL` | (obligatoria) | URL HTTPS pública que verá el navegador. |
  | `DB_NAME` | `postgres` | Nombre de la base de datos de esta app dentro del Postgres compartido (una base por app: p. ej. `mvp_inventario`). |
  | `DB_USER` | `homebox_app` | Rol SQL. Si usas pooler, define aquí el usuario con sufijo `.REF`. |
  | `DB_SSLMODE` | `verify-full` | Modo TLS. Con `disable` o `require` no se exige `certs/ca.crt` ni `sslrootcert`. |
  | `DB_SSL_ROOT_CERT` | `/certs/ca.crt` | Ruta del CA dentro del contenedor. Con `DB_SSLMODE=verify-full` es obligatorio que el archivo sea legible; con `disable` libpq/pgx lo ignoran, así que no hace falta dejarla vacía. |
  | `TRUST_PROXY` | `true` | Activa `HBOX_OPTIONS_TRUST_PROXY` para confiar en `X-Forwarded-*` del proxy. Solo mantenerlo en `true` si la app está publicada exclusivamente detrás del proxy de Coolify/Traefik (que sanea los encabezados). Poner `false` si la app queda expuesta directamente o detrás de un proxy que no sanea encabezados. |

- `ops/start.sh` y `ops/preflight.sh` aceptan los modos válidos de libpq (`disable|allow|prefer|require|verify-ca|verify-full`). Exigen CA legible solo con `DB_SSLMODE=verify-full`; con `disable` (red interna Docker hacia el Postgres compartido) arrancan sin `certs/ca.crt`.
- El bootstrap privado se hace con el override `compose.bootstrap.yaml` (perfil temporal); no usar para producción.

## Límites
Homebox no reemplaza un ERP, POS, sistema de contabilidad, control de stock transaccional o mantenimiento industrial. Para ventas y movimientos contables evaluar Odoo; para activos empresariales y asignaciones formales evaluar Snipe-IT. Este producto se orienta a inventarios sencillos de equipos y objetos.

Validación realizada: configuración YAML, sintaxis de scripts y comprobaciones locales de integridad y guardas de recuperación. No se ejecutó Docker, migraciones, TLS ni aplicación real en este entorno. La compatibilidad práctica con tu proyecto Supabase queda pendiente del ensayo en servidor.
