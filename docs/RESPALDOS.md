# Respaldo y restauración
`python3 scripts/backup.py`

Detiene app, obtiene dump custom de public y tar de /data, copia configuración/.env/CA y genera manifiesto con SHA256. Reinicia app si estaba activa, incluso si falla una copia; una copia incompleta no tendrá estado completed. Ejecutar cuando no haya inicialización ni tareas de preparación activas. Incluye fotos, documentos, configuración nativa que pudiera existir en /data, hashes de cuentas, tokens y datos personales. Cifrar copias fuera del servidor, definir retención y restringir acceso.

`python3 scripts/check_backup.py backups/FECHA`

Comprueba producto/versión, lista exacta, hashes y rutas/tipos permitidos del tar. Los hashes detectan alteración accidental, no autentican un manifiesto frente a un atacante. No cubre roles ni configuración de Supabase, proxy, DNS o identidad externa.

Para recuperar: preparar otro servidor con el mismo kit y versión, proyecto Supabase dedicado con public vacío, rol creado y volumen data vacío. Mantener los archivos de configuración del kit iguales al respaldo; actualizar .env y CA con credenciales del destino. No arrancar app para crear tablas antes de restaurar.

`python3 scripts/restore.py /ruta/respaldo --accept-restored-content`

Verifica manifiesto/tar, exige servicios detenidos y destinos vacíos, comprueba conexión TLS y restaura public en una transacción. Después restaura /data y ajusta sus permisos. No usa DROP ni sobrescribe instalaciones ocupadas; deja app detenida. Si falla la fase de archivos después de restaurar DB, el destino queda incompleto: repetir en otro destino vacío. No hay transacción conjunta entre archivos y base.

La copia puede recuperar sesiones, API keys y contenido previamente eliminado; revocar lo necesario. Ensayar en dominio privado, controlar salida del entorno permitiendo DNS y Supabase. Una red Docker internal también bloquearía PostgreSQL externo; no utilizarla como supuesto aislamiento. Revisar recuperación nativa, acceso a adjuntos y usuarios antes de iniciar producción. No activar correo, webhooks o notificaciones del destino de ensayo hacia usuarios reales.

## Actualización
Leer notas oficiales, respaldar y probar recuperación. Probar versión nueva con copia en entorno separado. Cambiar versión y digest deliberadamente, ejecutar migraciones y aceptación. No degradar solo la imagen después de una migración: volver a la versión anterior junto con su base y archivos compatibles.
