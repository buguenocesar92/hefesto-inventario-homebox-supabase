# Pruebas requeridas en servidor
Registrar fecha, operador y evidencias:
- Compose válido; preflight conecta con homebox_app y ssl=true. Cambiar CA por una incorrecta debe rechazar conexión.
- Bootstrap únicamente en loopback por SSH. Registrar propietario y entrar. Reiniciar sin perder acceso.
- Retirar bootstrap; verificar que registro público está cerrado y no hay puerto 8117 expuesto. La existencia de una fila users no demuestra que el propietario tenga los permisos esperados: comprobarlos desde la interfaz.
- Crear ubicación, etiqueta y equipo de demostración con serie, compra y garantía. Probar búsqueda con tildes y CLP si está disponible en preferencias.
- Adjuntar foto y documento no sensibles, reiniciar app y comprobar acceso/persistencia. Desde incógnito y con usuario de otra colección comprobar que no se filtran archivos ni equipos.
- Probar cambio de datos, archivo/eliminación y exportación nativos; verificar QR/enlaces con dominio HTTPS correcto.
- Probar roles y membresías con dos cuentas y colecciones. No anunciar aislamiento comercial multicliente hasta completar esta prueba; preferir una instancia/proyecto por cliente.
- Probar recuperación de cuenta si se configuró SMTP; si no, documentar la limitación antes de entregar.
- Crear backup, comprobarlo y restaurarlo en otro proyecto/volumen vacío. Verificar inventario, fotos, cuentas y permisos. Intentar copia alterada y destino ocupado: deben rechazarse antes de escribir.
- Si se habilita API nativa, probar creación, uso limitado y revocación de una clave de prueba; no usar claves de producción en scripts de demostración.

Nada de lo anterior se da por ejecutado en la preparación local del ZIP.
