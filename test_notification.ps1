# Script para probar notificaciones push en la app Order QR Mobile (PowerShell)
#
# INSTRUCCIONES:
# 1. Obtener el Server Key de Firebase Console:
#    - Ir a: https://console.firebase.google.com/
#    - Seleccionar el proyecto
#    - Ir a Project Settings > Cloud Messaging
#    - Copiar el "Server Key"
# 2. Reemplazar "TU_SERVER_KEY_AQUI" con tu Server Key
# 3. Ejecutar: .\test_notification.ps1

# Token FCM del dispositivo (se muestra en los logs cuando la app inicia)
$FCM_TOKEN = "eeNbEyYCQqCzZVfTL9j8zn:APA91bGVDsQD91sKUmdDTrCCNwbriollnuoLpk1qpzixXAZOqX3BuL1N5_0mFUdjYk6p1IHw-24hyCuBcy8y6WQcyKIvDLR162T6Dl0aIFDO2hPg2IayRFY"

# Server Key de Firebase (obtener de Firebase Console > Project Settings > Cloud Messaging)
$SERVER_KEY = "TU_SERVER_KEY_AQUI"

Write-Host "======================================"
Write-Host "  PROBANDO NOTIFICACIONES PUSH"
Write-Host "======================================"
Write-Host ""
Write-Host "Token del dispositivo: $FCM_TOKEN"
Write-Host ""
Write-Host "Selecciona el tipo de notificación a enviar:"
Write-Host ""
Write-Host "1) Orden lista para recoger (pending -> ready)"
Write-Host "2) Orden entregada (ready -> delivered)"
Write-Host "3) Nueva orden asociada"
Write-Host "4) Orden cancelada"
Write-Host "5) Recordatorio de orden pendiente"
Write-Host ""
$option = Read-Host "Ingresa el número (1-5)"

switch ($option) {
  "1" {
    $TITLE = "¡Tu orden está lista!"
    $BODY = "La orden ORD-2025-001 está lista para recoger"
    $TYPE = "order_status_change"
    $ORDER_ID = "2"
    $ORDER_NUMBER = "ORD-2025-001"
    $OLD_STATUS = "pending"
    $NEW_STATUS = "ready"
  }
  "2" {
    $TITLE = "Orden entregada"
    $BODY = "La orden ORD-2025-001 ha sido entregada exitosamente"
    $TYPE = "order_status_change"
    $ORDER_ID = "2"
    $ORDER_NUMBER = "ORD-2025-001"
    $OLD_STATUS = "ready"
    $NEW_STATUS = "delivered"
  }
  "3" {
    $TITLE = "Nueva orden asociada"
    $BODY = "Se ha asociado la orden ORD-2025-002 a tu dispositivo"
    $TYPE = "order_associated"
    $ORDER_ID = "3"
    $ORDER_NUMBER = "ORD-2025-002"
    $OLD_STATUS = ""
    $NEW_STATUS = "pending"
  }
  "4" {
    $TITLE = "Orden cancelada"
    $BODY = "La orden ORD-2025-001 ha sido cancelada"
    $TYPE = "order_cancelled"
    $ORDER_ID = "2"
    $ORDER_NUMBER = "ORD-2025-001"
    $OLD_STATUS = "pending"
    $NEW_STATUS = "cancelled"
  }
  "5" {
    $TITLE = "Recordatorio"
    $BODY = "Tienes órdenes pendientes por recoger"
    $TYPE = "order_reminder"
    $ORDER_ID = "2"
    $ORDER_NUMBER = "ORD-2025-001"
    $OLD_STATUS = ""
    $NEW_STATUS = ""
  }
  default {
    Write-Host "Opción inválida"
    exit 1
  }
}

Write-Host ""
Write-Host "Enviando notificación..."
Write-Host "  Título: $TITLE"
Write-Host "  Cuerpo: $BODY"
Write-Host "  Tipo: $TYPE"
Write-Host ""

# Construir el body JSON
$body = @{
  to = $FCM_TOKEN
  notification = @{
    title = $TITLE
    body = $BODY
    sound = "default"
  }
  data = @{
    type = $TYPE
    order_id = $ORDER_ID
    order_number = $ORDER_NUMBER
    old_status = $OLD_STATUS
    new_status = $NEW_STATUS
    folio_number = "TEST-001"
    click_action = "FLUTTER_NOTIFICATION_CLICK"
  }
  priority = "high"
  content_available = $true
} | ConvertTo-Json -Depth 10

# Enviar notificación usando FCM API
try {
  $response = Invoke-RestMethod -Uri "https://fcm.googleapis.com/fcm/send" `
    -Method Post `
    -Headers @{
      "Authorization" = "key=$SERVER_KEY"
      "Content-Type" = "application/json"
    } `
    -Body $body

  Write-Host "Respuesta del servidor:"
  $response | ConvertTo-Json -Depth 10
  Write-Host ""

  if ($response.success -eq 1) {
    Write-Host "✅ Notificación enviada exitosamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verifica:"
    Write-Host "  - Si la app está abierta (foreground): Deberías ver una notificación local"
    Write-Host "  - Si la app está en background: Deberías ver una notificación del sistema"
    Write-Host "  - Si la app está cerrada: Deberías ver una notificación del sistema"
    Write-Host "  - Al tocar la notificación: Debería abrir el detalle de la orden"
  } else {
    Write-Host "❌ Error al enviar notificación" -ForegroundColor Red
    Write-Host ""
    Write-Host "Posibles causas:"
    Write-Host "  1. El Server Key es incorrecto"
    Write-Host "  2. El token FCM ha expirado o es inválido"
    Write-Host "  3. El proyecto de Firebase no está configurado correctamente"
  }
} catch {
  Write-Host "❌ Error al enviar la solicitud:" -ForegroundColor Red
  Write-Host $_.Exception.Message
  Write-Host ""
  Write-Host "Posibles causas:"
  Write-Host "  1. El Server Key es incorrecto"
  Write-Host "  2. No hay conexión a internet"
  Write-Host "  3. El formato del token es inválido"
}
