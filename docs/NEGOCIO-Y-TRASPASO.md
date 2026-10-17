# Venta y traspaso
Oferta posible: instalación de inventario sencillo para oficinas pequeñas, talleres, estudios y hogares; organización de ubicaciones, carga inicial, etiquetas QR, formación, backups y soporte mensual. Cotizar según alcance real, almacenamiento y retención; no se incluyen estimaciones de ingresos ni precios de terceros.

Para procesos con ventas, bodega y contabilidad, evaluar Odoo. Para asignación formal de activos, usar Snipe-IT. No duplicar funcionalidades de esos productos prometiendo un ERP con Homebox.

El archivo plantillas/carga-manual.csv contiene un ejemplo ficticio: sirve como hoja de preparación. No se ha validado como formato nativo de importación. La plantilla Markdown de entrega es un documento operativo, no un módulo de firma electrónica.

## Migración
Para mover Homebox completo a otro VPS, restaurar DB y /data con la misma versión, revisar dominio/QR y ensayar antes del cambio DNS. Exportar una colección con las opciones nativas puede ser útil, pero no se supone equivalente al backup completo de instancia.

Para Odoo, obtener exportación nativa real, revisar sus campos y mapear nombre, serie, ubicación, compra y garantía al módulo/modelo elegido. Hacer una importación de prueba y reconciliar cantidades, adjuntos y referencias antes de importar todo. Homebox no define por sí solo valoración contable ni movimientos de stock de Odoo. No se incluye conector, sincronización automática ni CSV garantizado para un modelo Odoo específico.

Homebox ofrece API nativa; integrar a través de sus contratos y permisos de esta versión. Este paquete no implementa un nuevo servicio REST ni un cliente n8n. Verificar autenticación, límites y revocación antes de usarla desde terceros.

## Licencia
Homebox usa AGPL-3.0; se adjunta LICENSE-Homebox.txt. Mantener avisos y cumplir las obligaciones de código fuente aplicables si se modifica y ofrece por red. El kit no concede derechos adicionales sobre la marca original. Se vende instalación, adaptación y soporte según licencia y alcance acordado.
