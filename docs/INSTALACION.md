# Instalación y primera cuenta
Requisitos: Docker Compose v2, Python 3.11+ para scripts, proxy HTTPS y conectividad al endpoint Supabase. Inicio orientativo para equipo pequeño: 1–2 vCPU, 1–2 GB RAM y almacenamiento según adjuntos; medir antes de comprometer capacidad.

## Base de datos
Usar conexión directa 5432 al proyecto dedicado. El endpoint puede requerir IPv6; verificar ruta desde el VPS. El kit no adapta usuario/puerto al pooler. No usar pooler en modo transacción ni desactivar TLS para resolver problemas de conexión. Descargar CA del proyecto desde Supabase y conservarla legible para UID 65532 en el montaje de solo lectura.

Ejecutar sql/01-admin.sql solo en proyecto exclusivo con public vacío. Las migraciones nativas se ejecutan al iniciar app con homebox_app. No asignar superusuario. No exponer las tablas mediante API pública de Supabase: revisar permisos y configuración Data API del proyecto; no entregar claves anon/service_role al navegador.

El servicio preflight comprueba rol, versión PG y permisos; en modo normal exige que ya exista una cuenta. Este control no verifica identidad ni privilegios del propietario y no sustituye la aceptación manual. Un servidor PG superior a 17 exige adaptar y ensayar también pg_dump antes de usar el kit.

## Bootstrap privado
No configurar todavía un dominio público en Coolify ni publicar app en otro proxy. En servidor:

`docker compose -f compose.yaml -f compose.bootstrap.yaml up -d app`

Desde tu equipo:

`ssh -N -L 8117:127.0.0.1:8117 usuario@servidor`

Abrir http://localhost:8117, registrar la cuenta del propietario y comprobar login. Este acceso HTTP es solo por túnel SSH en equipo de confianza. Crear las cuentas necesarias y comprobar los grupos/colecciones usando las opciones nativas. No asumir que registrarse crea automáticamente un administrador global de toda la instancia.

Finalizar bootstrap:

`docker compose -f compose.yaml -f compose.bootstrap.yaml down`

Nunca añadir -v. Iniciar luego solo con compose.yaml: `docker compose up -d app`. Esto elimina el puerto temporal y vuelve HBOX_OPTIONS_ALLOW_REGISTRATION=false. El servicio permissions ajusta el volumen a UID/GID 65532; app conserva usuario rootless y ejecuta el binario nativo. Las tareas de preparación pueden aparecer terminadas con código 0: es lo esperado.

## Coolify
Importar repositorio privado con compose.yaml. Mantener ops y certs junto al Compose, cargar variables sin versionar .env, conservar volumen data y asignar HTTPS al servicio app, puerto interno 7745. No exponer preflight, dbtools o filetools. No publicar puerto PostgreSQL. Comprobar encabezados y hostname de enlaces/QR después de activar el proxy. Trust proxy queda desactivado; habilitarlo solo si se ha comprobado que app es accesible exclusivamente desde el proxy de confianza.

## Correo e identidad
El login local puede utilizarse sin correo, pero este kit no configura recuperación por email ni garantiza invitaciones por correo. Si el uso lo requiere, configurar y validar las variables HBOX_MAILER_* oficiales con un proveedor real antes de entregar el servicio. No guardar datos sensibles hasta verificar recuperación de acceso. OIDC es una ampliación nativa posible, no está activado. No se promete MFA local ni integración con Supabase Auth.
