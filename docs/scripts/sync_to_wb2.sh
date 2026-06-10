#!/bin/bash
WB2_IP="IP_PUBLICA_WB2"
KEY_PATH="/home/ec2-user/NexOrder-SSH-Key.pem"

echo "Sincronizando NexOrder desde WB1 a WB2..."
rsync -avz -e "ssh -i $KEY_PATH" /var/www/nexorder/ ec2-user@$WB2_IP:/var/www/nexorder/

if [ $? -eq 0 ]; then
    echo "✅ Sincronización completada exitosamente"
else
    echo "❌ Error al sincronizar"
    exit 1
fi

echo "Recargando Apache en WB2..."
ssh -i $KEY_PATH ec2-user@$WB2_IP "sudo systemctl reload httpd"

echo "✅ Apache recargado en WB2"
