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

## Límites
Homebox no reemplaza un ERP, POS, sistema de contabilidad, control de stock transaccional o mantenimiento industrial. Para ventas y movimientos contables evaluar Odoo; para activos empresariales y asignaciones formales evaluar Snipe-IT. Este producto se orienta a inventarios sencillos de equipos y objetos.

Validación realizada: configuración YAML, sintaxis de scripts y comprobaciones locales de integridad y guardas de recuperación. No se ejecutó Docker, migraciones, TLS ni aplicación real en este entorno. La compatibilidad práctica con tu proyecto Supabase queda pendiente del ensayo en servidor.
