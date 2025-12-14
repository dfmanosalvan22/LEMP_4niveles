# Infraestructura LEMP en alta disponibilidad en 4 Capas

## Índice
1. [Introducción](#introducción)
2. [Arquitectura de la Infraestructura](#arquitectura-de-la-infraestructura)
3. [Direccionamiento IP](#direccionamiento-ip)
4. [Instalación y Configuración](#instalación-y-configuración)
   - [Capa 4: Cluster MariaDB Galera](#capa-4-cluster-mariadb-galera)
   - [Capa 3: Proxy HAProxy](#capa-3-proxy-haproxy)
   - [Capa 2: Servidor NFS y PHP-FPM](#capa-2-servidor-nfs-y-php-fpm)
   - [Capa 2: Servidores Web Nginx](#capa-2-servidores-web-nginx)
   - [Capa 1: Balanceador de Carga](#capa-1-balanceador-de-carga)
5. [Verificación del Funcionamiento](#verificación-del-funcionamiento)
6. [Conclusión](#conclusión)
7. [Aplicación Web Desplegada](#aplicación-web-desplegada)

---

## Introducción

Este proyecto implementa una **infraestructura web en alta disponibilidad** basada en la pila **LEMP** (Linux, Nginx, MariaDB, PHP), organizada en **4 capas independientes**.  
El diseño busca aislar responsabilidades, mejorar la seguridad y garantizar tolerancia a fallos mediante balanceo de carga y replicación de datos.

### Objetivos del proyecto
- Desplegar una aplicación web de gestión de usuarios
- Implementar alta disponibilidad en todas las capas
- Separar servicios mediante redes privadas
- Usar NFS como almacenamiento compartido
- Implementar un clúster MariaDB Galera con replicación síncrona
- Balancear conexiones a base de datos mediante HAProxy
- Automatizar el despliegue con Vagrant y scripts Bash

---

## Arquitectura de la Infraestructura

La infraestructura está compuesta por **8 máquinas virtuales**, organizadas en **4 capas** claramente diferenciadas.
```
              ┌─────────────────────────────────────────────────────────────┐
              │                    CAPA 1 - PÚBLICA                         │
              │  ┌────────────────────────────────────────────────────┐     │
              │  │        Balanceador Nginx (balanceadorfelipe)       │     │
              │  │              IP: 192.168.10.10                     │     │
              │  │              Puerto público: 8080                  │     │
              │  └────────────────────────────────────────────────────┘     │
              └─────────────────────────────────────────────────────────────┘
                                          │
                                 ┌────────┴────────┐
                                 │  REDINTERNA1    │
                                 │  192.168.10.0   │
                                 └────────┬────────┘
                                          │
              ┌─────────────────────────────────────────────────────────────┐
              │                    CAPA 2 - BACKEND                         │
              │  ┌───────────────────────┐    ┌───────────────────────┐     │
              │  │   Servidor Web 1      │    │   Servidor Web 2      │     │
              │  │  (serverweb1felipe)   │    │  (serverweb2felipe)   │     │
              │  │  IP1: 192.168.10.20   │    │  IP1: 192.168.10.30   │     │
              │  │  IP2: 192.168.20.20   │    │  IP2: 192.168.20.30   │     │
              │  └───────────────────────┘    └───────────────────────┘     │
              │           │                              │                  │
              │           └──────────┬───────────────────┘                  │
              │                      │                                      │
              │              ┌───────┴────────┐                             │
              │              │  REDINTERNA2   │                             │
              │              │  192.168.20.0  │                             │
              │              └───────┬────────┘                             │
              │                      │                                      │
              │         ┌────────────────────────────┐                      │
              │         │   Servidor NFS + PHP-FPM   │                      │
              │         │    (servernfsfelipe)       │                      │
              │         │   IP1: 192.168.20.10       │                      │
              │         │   IP2: 192.168.30.20       │◄──┐                  │
              │         └────────────────────────────┘   │                  │
              │                      │                   │                  │
              └──────────────────────┼───────────────────┼──────────────────┘
                                     │                   │
                            ┌────────┴────────┐          │
                            │  REDINTERNA3    │          │
                            │  192.168.30.0   │◄─────────┘
                            └────────┬────────┘
                                     │
              ┌──────────────────────┼──────────────────────────────────────┐
              │         CAPA 3 - PROXY BASE DE DATOS                        │
              │         ┌────────────────────────────┐                      │
              │         │     HAProxy                │                      │
              │         │  (proxybbddfelipe)         │                      │
              │         │  IP1: 192.168.30.10        │                      │
              │         │  IP2: 192.168.40.10        │                      │
              │         │  Puerto: 3306              │                      │
              │         └────────────────────────────┘                      │
              └─────────────────────────────────────────────────────────────┘
                                          │
                                 ┌────────┴────────┐
                                 │  REDINTERNA4    │
                                 │  192.168.40.0   │
                                 └────────┬────────┘
                                          │
                             ┌────────────┼────────────┐
                             │            │            │
              ┌────────────────────────────────────────────────────────────┐
              │                CAPA 4 - BASE DE DATOS                      │
              │  ┌───────────┐    ┌───────────┐    ┌───────────┐           │
              │  │  MariaDB  │    │  MariaDB  │    │  MariaDB  │           │
              │  │   Nodo 1  │    │   Nodo 2  │    │   Nodo 3  │           │
              │  │ (serverdb │    │ (serverdb │    │ (serverdb │           │
              │  │ 1felipe)  │◄───┤ 2felipe)  │◄───┤ 3felipe)  │           │
              │  │.40.20     │───►│.40.21     │───►│.40.22     │           │
              │  └───────────┘    └───────────┘    └───────────┘           │
              │         Cluster Galera - Replicación Síncrona              │
              └────────────────────────────────────────────────────────────┘

IMPORTANTE: Los servidores web NO tienen acceso directo a REDINTERNA3.
Solo el servidor NFS se conecta al HAProxy de base de datos.
```


### Principio de seguridad clave

- **Los servidores web NO tienen acceso directo a la base de datos**
- **Solo el servidor NFS (con PHP-FPM) puede conectarse al HAProxy**
- Todo acceso a la base de datos pasa por PHP-FPM

---
## Descripción de las capas

### Capa 1: Balanceador

Esta capa está compuesta por una única máquina denominada **balanceadorfelipe**, cuya función es distribuir el tráfico HTTP entrante entre los servidores web disponibles. El servicio se encuentra expuesto al host a través del **puerto 8080**, actuando como punto de entrada principal a la arquitectura y garantizando una distribución eficiente de las solicitudes.

### Capa 2: Backend Web

El backend web está formado por **dos servidores Nginx** encargados de servir el contenido web y por **un servidor NFS que ejecuta PHP-FPM**. Los servidores web no acceden de forma directa a la base de datos; en su lugar, el procesamiento de PHP se realiza de manera remota en el servidor NFS, lo que permite centralizar la ejecución del código y simplificar la gestión del entorno de aplicación.

### Capa 3: Proxy de Base de Datos

Esta capa cuenta con **un servidor HAProxy** que actúa como intermediario entre la capa web y la base de datos. Su responsabilidad principal es **balancear las conexiones MySQL** y dirigirlas de forma transparente hacia el cluster Galera, proporcionando alta disponibilidad y una distribución adecuada de la carga.

### Capa 4: Base de Datos

La capa de base de datos está compuesta por **tres nodos MariaDB** configurados en un **cluster Galera**. Este cluster opera con **replicación síncrona multi-master**, lo que permite que todos los nodos acepten escrituras, manteniendo la consistencia de los datos y mejorando tanto la disponibilidad como la tolerancia a fallos.

## Direccionamiento IP

### REDINTERNA1 – 192.168.10.0/24 (Capa pública)
| Máquina | IP |
|------|----|
| balanceadorfelipe | 192.168.10.10 |
| serverweb1felipe | 192.168.10.20 |
| serverweb2felipe | 192.168.10.30 |

### REDINTERNA2 – 192.168.20.0/24 (NFS)
| Máquina | IP |
|------|----|
| servernfsfelipe | 192.168.20.10 |
| serverweb1felipe | 192.168.20.20 |
| serverweb2felipe | 192.168.20.30 |

### REDINTERNA3 – 192.168.30.0/24 (Proxy BBDD)
| Máquina | IP |
|------|----|
| proxybbddfelipe | 192.168.30.10 |
| servernfsfelipe | 192.168.30.20 |

### REDINTERNA4 – 192.168.40.0/24 (Cluster Galera)
| Máquina | IP |
|------|----|
| proxybbddfelipe | 192.168.40.10 |
| serverdb1felipe | 192.168.40.20 |
| serverdb2felipe | 192.168.40.21 |
| serverdb3felipe | 192.168.40.22 |

---

## Instalación y Configuración

### Capa 4: Cluster MariaDB Galera

El cluster MariaDB Galera proporciona replicación síncrona multi-master, garantizando que todos los nodos tengan los mismos datos en tiempo real.
Características:

- Replicación síncrona: Todos los nodos deben confirmar las escrituras
- Multi-master: Cualquier nodo puede aceptar escrituras
- Detección automática de fallos: Si un nodo falla, el cluster continúa operando

#### Script `scripts/galera.sh`

```bash
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
```

### Capa 3: Proxy HAProxy 

HAProxy actúa como **balanceador de carga para las conexiones MySQL**, distribuyendo las peticiones entre los 3 nodos del cluster Galera. Garantiza alta disponibilidad y tolerancia a fallos, permitiendo que los servidores web se conecten a un único punto de acceso a la base de datos.
#### Script `scripts/haproxy.sh`

El script realiza las siguientes acciones:

- Instala HAProxy.
- Configura el balanceo TCP en el puerto 3306.
- Define los tres servidores MariaDB como backend.
- Habilita y arranca el servicio.

```bash
#!/bin/bash

sudo apt update
sudo apt install -y haproxy

# Configurar HAProxy
cat > /etc/haproxy/haproxy.cfg << 'EOF'
global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log global
    mode tcp
    timeout connect 5000
    timeout client 50000
    timeout server 50000

# Configuración en /etc/haproxy/haproxy.cfg
# - Escucha en puerto 3306
# - Balance roundrobin entre los 3 nodos

listen mysql
    bind 192.168.30.10:3306
    mode tcp
    balance roundrobin
    option mysql-check user haproxy_check
    server mariadb1 192.168.40.20:3306 check
    server mariadb2 192.168.40.21:3306 check
    server mariadb3 192.168.40.22:3306 check
EOF

# Reiniciar HAProxy
systemctl restart haproxy
systemctl enable haproxy

ip route del default

echo "HAProxy configurado"
```
### Capa 2: Servidor NFS y PHP-FPM

El servidor NFS centraliza **el código PHP y los recursos web**, y además ejecuta **PHP-FPM remoto**, permitiendo que los servidores web únicamente sirvan contenido estático y deleguen la ejecución de PHP.
#### Script `scripts/nfs.sh`

El script realiza:

- Instalación de NFS y PHP-FPM.
- Creación del directorio `/var/nfs/share` y configuración de permisos.
- Configuración de `/etc/exports` para permitir acceso desde los servidores web.
- Configuración de PHP-FPM para escuchar por TCP (`192.168.20.10:9000`).
- Descarga de la aplicación de ejemplo y copia al NFS.
- Creación del archivo `config.php` con la conexión a la base de datos.
- Habilitación de servicios y ajustes de red para Vagrant.

```bash
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
```

### Capa 2: Servidores Web Nginx

Los servidores web montan **el recurso compartido NFS** en `/var/www/html` y usan **Nginx** para servir contenido web y **reenviar las peticiones PHP a PHP-FPM remoto**.
#### Script `scripts/serverweb.sh`

El script realiza:

- Instalación de Nginx y cliente NFS.
- Montaje del directorio NFS en `/var/www/html`.
- Configuración de Nginx para servir PHP vía FastCGI a PHP-FPM en el servidor NFS.
- Habilitación de Nginx y ajustes de red en Vagrant.

```bash
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
```

### Capa 1: Balanceador de Carga

Su función es distribuir el tráfico HTTP entre los servidores web. Este balanceador permite:
#### Script `scripts/balanceador.sh`

- Escalabilidad horizontal de los servidores web.
- Alta disponibilidad frente a fallos de un nodo.
- Acceso unificado para el usuario final.

```bash
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
```

## Verificación del Funcionamiento

Link vídeo: https://youtu.be/Mkb2RlpXzME


## Conclusión

En esta actividad se diseñó e implementó una arquitectura distribuida tipo **LAMP** utilizando **Vagrant**, con el objetivo de comprender el funcionamiento y la integración de distintos servicios en un entorno realista. La solución se estructuró en varias capas claramente diferenciadas, lo que permitió aplicar principios básicos de **escalabilidad, alta disponibilidad y separación de responsabilidades**.

Se configuró un **cluster de bases de datos MariaDB Galera**, garantizando replicación síncrona y tolerancia a fallos entre nodos. Sobre este cluster se desplegó **HAProxy** como balanceador de carga en modo TCP, proporcionando un punto único de acceso a la base de datos y permitiendo distribuir las conexiones de forma transparente para los servidores web.

Por otro lado, se implementó un **servidor NFS** que centraliza el código de la aplicación y actúa además como **servidor PHP-FPM remoto**, lo que facilitó la compartición del contenido entre múltiples servidores web y evitó duplicidad de datos. Los **servidores web Nginx** montan dicho recurso NFS y delegan la ejecución de scripts PHP al servicio PHP-FPM, manteniendo así una arquitectura desacoplada y modular.

Durante el desarrollo de la actividad se identificaron y resolvieron problemas habituales en entornos distribuidos, especialmente relacionados con **rutas de archivos, configuración de FastCGI, permisos NFS y conectividad entre servicios**. Esto permitió afianzar conceptos clave como la coherencia de rutas entre sistemas, la importancia del orden de arranque en Vagrant y la correcta comunicación entre capas.

En conjunto, la práctica demuestra cómo es posible construir un entorno web completo y funcional basado en software libre, simulando escenarios de producción y reforzando el entendimiento de tecnologías ampliamente utilizadas en infraestructuras modernas.
