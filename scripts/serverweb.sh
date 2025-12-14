#!/bin/bash

echo "INSTALANDO SERVIDOR WEB"

# Actualiza el sistema e instala: Nginx y Cliente NFS para montar el share remoto
sudo apt update
sudo apt upgrade -y
sudo apt install -y nginx nfs-common


# Directorio donde se montará el contenido compartido
mkdir -p /var/www/html


# Espera a que el servidor NFS esté disponible
echo "Esperando al servidor NFS"
sleep 30

# Monta el directorio compartido en la ruta usada por Nginx
mount -t nfs 192.168.20.10:/var/nfs/share /var/www/html

# Hace persistente el montaje tras reinicio
echo "192.168.20.10:/var/nfs/share /var/www/html nfs defaults 0 0" >> /etc/fstab


# Nginx sirve los archivos desde NFS y envía los scripts PHP al PHP-FPM remoto
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~ \.php$ {
        fastcgi_pass 192.168.20.10:9000;
        fastcgi_index index.php;

        # IMPORTANTE:
        # SCRIPT_FILENAME debe coincidir con la ruta que PHP-FPM ve en el servidor NFS
        fastcgi_param SCRIPT_FILENAME /var/nfs/share$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Aplica la configuración y habilita Nginx al inicio
systemctl restart nginx
systemctl enable nginx

# Eliminación de la ruta por defecto para evitar conflictos
ip route del default

echo "Servidor web configurado"