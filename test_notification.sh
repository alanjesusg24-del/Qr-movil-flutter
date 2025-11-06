#!/bin/bash

# Script para probar notificaciones push en la app Order QR Mobile
#
# INSTRUCCIONES:
# 1. Obtener el Server Key de Firebase Console:
#    - Ir a: https://console.firebase.google.com/
#    - Seleccionar el proyecto
#    - Ir a Project Settings > Cloud Messaging
#    - Copiar el "Server Key"
# 2. Reemplazar "TU_SERVER_KEY_AQUI" con tu Server Key
# 3. Ejecutar: bash test_notification.sh

# Token FCM del dispositivo (se muestra en los logs cuando la app inicia)
FCM_TOKEN="eeNbEyYCQqCzZVfTL9j8zn:APA91bGVDsQD91sKUmdDTrCCNwbriollnuoLpk1qpzixXAZOqX3BuL1N5_0mFUdjYk6p1IHw-24hyCuBcy8y6WQcyKIvDLR162T6Dl0aIFDO2hPg2IayRFY"

# Server Key de Firebase (obtener de Firebase Console > Project Settings > Cloud Messaging)
SERVER_KEY="TU_SERVER_KEY_AQUI"

echo "======================================"
echo "  PROBANDO NOTIFICACIONES PUSH"
echo "======================================"
echo ""
echo "Token del dispositivo: $FCM_TOKEN"
echo ""
echo "Selecciona el tipo de notificación a enviar:"
echo ""
echo "1) Orden lista para recoger (pending -> ready)"
echo "2) Orden entregada (ready -> delivered)"
echo "3) Nueva orden asociada"
echo "4) Orden cancelada"
echo "5) Recordatorio de orden pendiente"
echo ""
read -p "Ingresa el número (1-5): " option

case $option in
  1)
    TITLE="¡Tu orden está lista!"
    BODY="La orden ORD-2025-001 está lista para recoger"
    TYPE="order_status_change"
    ORDER_ID="2"
    ORDER_NUMBER="ORD-2025-001"
    OLD_STATUS="pending"
    NEW_STATUS="ready"
    ;;
  2)
    TITLE="Orden entregada"
    BODY="La orden ORD-2025-001 ha sido entregada exitosamente"
    TYPE="order_status_change"
    ORDER_ID="2"
    ORDER_NUMBER="ORD-2025-001"
    OLD_STATUS="ready"
    NEW_STATUS="delivered"
    ;;
  3)
    TITLE="Nueva orden asociada"
    BODY="Se ha asociado la orden ORD-2025-002 a tu dispositivo"
    TYPE="order_associated"
    ORDER_ID="3"
    ORDER_NUMBER="ORD-2025-002"
    OLD_STATUS=""
    NEW_STATUS="pending"
    ;;
  4)
    TITLE="Orden cancelada"
    BODY="La orden ORD-2025-001 ha sido cancelada"
    TYPE="order_cancelled"
    ORDER_ID="2"
    ORDER_NUMBER="ORD-2025-001"
    OLD_STATUS="pending"
    NEW_STATUS="cancelled"
    ;;
  5)
    TITLE="Recordatorio"
    BODY="Tienes órdenes pendientes por recoger"
    TYPE="order_reminder"
    ORDER_ID="2"
    ORDER_NUMBER="ORD-2025-001"
    OLD_STATUS=""
    NEW_STATUS=""
    ;;
  *)
    echo "Opción inválida"
    exit 1
    ;;
esac

echo ""
echo "Enviando notificación..."
echo "  Título: $TITLE"
echo "  Cuerpo: $BODY"
echo "  Tipo: $TYPE"
echo ""

# Enviar notificación usando FCM v1 API
response=$(curl -s -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=$SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"to\": \"$FCM_TOKEN\",
    \"notification\": {
      \"title\": \"$TITLE\",
      \"body\": \"$BODY\",
      \"sound\": \"default\"
    },
    \"data\": {
      \"type\": \"$TYPE\",
      \"order_id\": \"$ORDER_ID\",
      \"order_number\": \"$ORDER_NUMBER\",
      \"old_status\": \"$OLD_STATUS\",
      \"new_status\": \"$NEW_STATUS\",
      \"folio_number\": \"TEST-001\",
      \"click_action\": \"FLUTTER_NOTIFICATION_CLICK\"
    },
    \"priority\": \"high\",
    \"content_available\": true
  }")

echo "Respuesta del servidor:"
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# Verificar si fue exitoso
if echo "$response" | grep -q '"success": 1'; then
  echo "✅ Notificación enviada exitosamente!"
  echo ""
  echo "Verifica:"
  echo "  - Si la app está abierta (foreground): Deberías ver una notificación local"
  echo "  - Si la app está en background: Deberías ver una notificación del sistema"
  echo "  - Si la app está cerrada: Deberías ver una notificación del sistema"
  echo "  - Al tocar la notificación: Debería abrir el detalle de la orden"
else
  echo "❌ Error al enviar notificación"
  echo ""
  echo "Posibles causas:"
  echo "  1. El Server Key es incorrecto"
  echo "  2. El token FCM ha expirado o es inválido"
  echo "  3. El proyecto de Firebase no está configurado correctamente"
fi
