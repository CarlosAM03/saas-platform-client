# Piloto privado del owner — deshabilitado por defecto

Este modo no se ejecuta durante QA y no autoriza envíos del agente. Requiere el
manifiesto con E2E sintético aprobado y confirmación del owner para destinatario,
momento y gasto cero. No introducir el correo institucional en comandos,
fixtures, prompts, archivos ni evidencias públicas: el owner lo escribe en la UI.

## Preparación privada

El owner comprueba en Brevo que dispone de API key transaccional y remitente
verificado. La credencial SMTP no es la API key. Debe controlar el dominio y
seguir los registros DKIM/DMARC que indique su cuenta; revisar SPF cuando aplique.
Ver [autenticación oficial del dominio](https://help.brevo.com/hc/en-us/articles/12163873383186-Authenticate-your-domain-with-Brevo-Brevo-code-DKIM-DMARC).
Comprobar cuota Free disponible y ausencia de facturación automática en su cuenta;
si falta dominio/remitente/cuota, detenerse, sin contratar ni fallback.

Backend usa exclusivamente POST HTTPS443 /v3/smtp/email con api-key, timeout15s,
sin redirects ni retries. [Contrato oficial del proveedor](https://developers.brevo.com/reference/send-transac-email).
HTTP201/messageId acredita aceptación; la entrega requiere el evento del proveedor
y la recepción visible que el owner atestará de forma privada.

## Activación consciente, solo por el owner

Ejecutar desde Flutter, después de revisar el manifiesto y detener los runners:

~~~powershell
./tool/frontend-adr006/Start-OwnerEmailPilot.ps1
# Devuelve PILOT_DISABLED y no altera el laboratorio.

# Solo el owner, con destinatario/momento/gasto ya aprobados:
./tool/frontend-adr006/Start-OwnerEmailPilot.ps1 -EnableRealBrevo -ConfirmVerifiedSender -ConfirmFreeQuota -ConfirmSingleManualSend
~~~

El script verifica candidato, PostgreSQL16 local y gates; pide remitente y API key
en la terminal privada. No pide destinatario ni contraseña del buzón. La clave no
se escribe al repositorio. La configuración específica contiene placeholders y
vive en .local ignorado. Solo la API obtiene una red de salida; el host Brevo se
resuelve públicamente en ese contenedor y mantiene TLS público verificable, sin
CA falsa ni cambios DNS de Windows. El piloto desactiva persistencia de logs de
esa API para evitar registrar datos personales del owner. No hace solicitudes de
envío: exclusivamente una acción posterior del owner en la UI crea el alta.

Usar el navegador confinado por noVNC en loopback18650: ya confía en la CA local.
El enlace https://localhost:18643 funciona en ese navegador. Desde un teléfono,
localhost apunta al teléfono: no usarlo ni exponer el servidor sin otra aprobación.

El owner inicia sesión ADMIN y completa los cuatro campos, escribiendo él mismo
su correo institucional. Comprueba un POST201 y luego Brevo/evento de entrega,
buzón/spam, enlace limpio, contraseña exclusiva de laboratorio, LOGIN_REQUIRED,
login OWNER y aislamiento. No entregar al agente acceso al buzón ni capturas
privadas. Conservar solo una atestación redactada de fecha/SHA/resultados fuera
de GitHub; jamás token, enlace completo, JWT, clave o correo completo.

Si no llega el mensaje tras201, revisar evento/bounce, dominio, remitente, cuota
y políticas institucionales. No reenviar repetidamente. Si hubo resend, usar
únicamente la generación nueva. Restaurar el laboratorio sintético ejecutando
Start-Lab.ps1, sin el override del piloto; no conservar el modo real en automatismos.

Hasta la prueba humana:
CORREO_REAL_ENTREGA=NOT RUN; PILOTO_OWNER_INSTITUCIONAL=OWNER_ACTION_REQUIRED.
La promoción Render/Vercel, migración Supabase y dos merges siguen reservados al
owner. Preparar este modo no acredita producción ni recepción real.
