#!/bin/bash

echo "INSTALANDO BALANCEADOR NGINX"
sudo apt update
sudo apt install -y nginx

cat > /etc/nginx/sites-available/balancer << 'EOF'
upstream backend {
    server 192.168.10.20:80;  # Servidor web 1
    server 192.168.10.30:80;  # Servidor web 2
}

server {
    listen 80;
    
    location / {
        proxy_pass http://backend;  # Envía tráfico a los servidores web
        proxy_set_header Host $host;  # Mantiene el host original
        proxy_set_header X-Real-IP $remote_addr;  # Pasa la IP del cliente
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;  # Encabezado para tracking
    }
}
EOF

# Activamos la configuración y eliminamos la default
ln -sf /etc/nginx/sites-available/balancer /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Reinicia Nginx para aplicar cambios y habilita al inicio
systemctl restart nginx
systemctl enable nginx

echo "Balanceador configurado"