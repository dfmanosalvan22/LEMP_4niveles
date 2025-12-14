#!/bin/bash

# IP del nodo Galera
NODE_IP=$1
# Nombre lógico del nodo
NODE_NAME=$2
# Indica si este nodo es el bootstrap del cluster
IS_BOOTSTRAP=$3

echo "INSTALANDO MARIADB GALERA CLUSTER"
echo "Nodo: $NODE_NAME ($NODE_IP)"

sudo apt update
sudo apt upgrade -y

sudo apt install -y mariadb-server mariadb-client galera-4 rsync

# Se detiene MariaDB antes de aplicar configuración Galera
sudo systemctl stop mariadb

# CONFIGURACIÓN DE GALERA
cat > /etc/mysql/mariadb.conf.d/60-galera.cnf << EOF
[mysqld]
# Escuchar en todas las interfaces
bind-address = 0.0.0.0
port = 3306
# Galera requiere binlog en formato ROW
binlog_format = ROW

default_storage_engine = InnoDB
innodb_autoinc_lock_mode = 2
innodb_flush_log_at_trx_commit = 0
innodb_buffer_pool_size = 256M

wsrep_on = ON
wsrep_provider = /usr/lib/galera/libgalera_smm.so
# Nombre lógico del cluster
wsrep_cluster_name = "galera_cluster"
# IPs de todos los nodos del cluster
wsrep_cluster_address = "gcomm://192.168.40.20,192.168.40.21,192.168.40.22"
wsrep_node_name = "$NODE_NAME"
wsrep_node_address = "$NODE_IP"
wsrep_sst_method = rsync
EOF

if [ "$IS_BOOTSTRAP" == "bootstrap" ]; then
    echo "Inicializando cluster (nodo bootstrap)"

    # Inicia el primer nodo del cluster Galera
    galera_new_cluster
    # Espera a que el cluster esté listo
    sleep 15
    
    mysql -u root << 'SQLEOF'
CREATE DATABASE IF NOT EXISTS lamp_db;

CREATE USER IF NOT EXISTS 'haproxy_check'@'%';
GRANT USAGE ON *.* TO 'haproxy_check'@'%';

CREATE USER IF NOT EXISTS 'lamp_user'@'%' IDENTIFIED BY 'lamp_password';
GRANT ALL PRIVILEGES ON lamp_db.* TO 'lamp_user'@'%';
FLUSH PRIVILEGES;

USE lamp_db;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL,
    email VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

INSERT INTO users (name, age, email) VALUES
('María García', 22, 'maria@123.com'),

SQLEOF

    echo "Nodo bootstrap configurado"
# NODOS SECUNDARIOS   
else
    echo "Uniéndose al cluster existente"
    
    sleep 45
    
    systemctl start mariadb
    
    sleep 20
    # Verifica si el nodo ya está en el cluster
    mysql -u root -e "SHOW STATUS LIKE 'wsrep_cluster_size';" 2>/dev/null || echo "Esperando sincronización..."
fi
# Habilita MariaDB al inicio del sistema
systemctl enable mariadb
# Elimina la ruta por defecto
ip route del default

echo "MariaDB Galera Cluster configurado"