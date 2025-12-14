#!/bin/bash

echo "INSTALANDO NFS + PHP-FPM"

# Actualiza repositorios e instala:
# NFS server para compartir archivos
# PHP-FPM para ejecutar PHP de forma remota
# Extensión MySQL y git para la aplicación

sudo apt update
sudo apt install -y nfs-kernel-server
sudo apt install -y php-fpm php-mysql git

# Directorio que se exportará a los servidores web
mkdir -p /var/nfs/share
chmod -R 777 /var/nfs/share 

# Se permite acceso RW a los servidores web
cat > /etc/exports << 'EOF'
/var/nfs/share 192.168.20.20(rw,sync,no_subtree_check,no_root_squash)
/var/nfs/share 192.168.20.30(rw,sync,no_subtree_check,no_root_squash)
EOF

# Recarga exports y asegura que NFS arranque con el sistema
exportfs -ra
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

# PHP-FPM escucha por TCP para que los web servers
# se conecten desde otras máquinas
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i 's/listen = .*/listen = 192.168.20.10:9000/' \
    /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

systemctl restart php${PHP_VERSION}-fpm
systemctl enable php${PHP_VERSION}-fpm

# Descargar la aplicación de ejemplo y la copia al NFS
cd /tmp
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git
cp -r iaw-practica-lamp/src/* /var/nfs/share/


# Archivo de configuración usado por los web servers
# Apunta al HAProxy de base de datos
cat > /var/nfs/share/config.php << 'EOF'
<?php
define("DB_HOST", "192.168.30.10");
define("DB_NAME", "lamp_db");
define("DB_USER", "lamp_user");
define("DB_PASSWORD", "lamp_password");

try {
    $mysqli = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
    if ($mysqli->connect_error) {
        die("Error de conexión: " . $mysqli->connect_error);
    }
} catch (Exception $e) {
    die("Error: " . $e->getMessage());
}
?>
EOF

# Permisos correctos para que PHP-FPM pueda leer los archivos
chown -R www-data:www-data /var/nfs/share
chmod -R 755 /var/nfs/share

# Eliminación de ruta por defecto para evitar conflictos
ip route del default 

echo "NFS y PHP-FPM configurados"



