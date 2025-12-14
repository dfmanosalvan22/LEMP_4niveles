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

