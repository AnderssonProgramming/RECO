#!/bin/bash
# Script de Monitoreo de Red - Slackware Linux
# Lab 07 - Redes de Computadores

# Colores para mejorar la presentación
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Función para el banner
show_banner() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     MONITOR DE RED - SLACKWARE LINUX                 ║${NC}"
    echo -e "${CYAN}║     Lab 07 - Infraestructura y Capa de Red           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para pausar
pause() {
    echo ""
    echo -e "${YELLOW}Presione ENTER para continuar...${NC}"
    read
}

# OPCIÓN 1: Información de Interfaces de Red
show_interfaces() {
    show_banner
    echo -e "${GREEN}═══ INTERFACES DE RED ═══${NC}\n"
    
    echo -e "${BLUE}📡 Interfaces Activas:${NC}"
    ifconfig | grep -E "^[a-z]|inet " | sed 's/^/  /'
    
    echo -e "\n${BLUE}📊 Resumen de Interfaces:${NC}"
    ip -s link | awk '/^[0-9]/ {print "  Interface:", $2} /RX:/ {getline; print "    ↓ Recibidos:", $1, "paquetes,", $2, "bytes"} /TX:/ {getline; print "    ↑ Enviados:", $1, "paquetes,", $2, "bytes"; print ""}'
    
    pause
}

# OPCIÓN 2: Conexiones de Red Activas
show_connections() {
    show_banner
    echo -e "${GREEN}═══ CONEXIONES DE RED ACTIVAS ═══${NC}\n"
    
    echo -e "${BLUE}🔌 Conexiones TCP Establecidas:${NC}"
    netstat -tn | grep ESTABLISHED | awk '{printf "  %s %-20s → %-20s\n", $6, $4, $5}' | head -20
    
    echo -e "\n${BLUE}📈 Estadísticas por Estado:${NC}"
    netstat -tan | awk '/^tcp/ {states[$6]++} END {for (state in states) printf "  %-15s: %d conexiones\n", state, states[state]}'
    
    echo -e "\n${BLUE}🌐 Top 5 IPs Conectadas:${NC}"
    netstat -tn | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5 | awk '{printf "  %s conexiones desde %s\n", $1, $2}'
    
    pause
}

# OPCIÓN 3: Tabla de Enrutamiento
show_routing() {
    show_banner
    echo -e "${GREEN}═══ TABLA DE ENRUTAMIENTO ═══${NC}\n"
    
    echo -e "${BLUE}🛣️  Rutas IPv4:${NC}"
    route -n | awk 'NR==1 {print "  " $0} NR>1 {printf "  %-18s %-18s %-18s %-8s %s\n", $1, $2, $3, $5, $8}'
    
    echo -e "\n${BLUE}📍 Gateway Predeterminado:${NC}"
    route -n | grep '^0.0.0.0' | awk '{printf "  Gateway: %s via %s\n", $2, $8}'
    
    echo -e "\n${BLUE}🔗 Rutas Detalladas con ip:${NC}"
    ip route show | sed 's/^/  /'
    
    pause
}

# OPCIÓN 4: Puertos Abiertos y Servicios
show_ports() {
    show_banner
    echo -e "${GREEN}═══ PUERTOS ABIERTOS Y SERVICIOS ═══${NC}\n"
    
    echo -e "${BLUE}🔓 Puertos TCP en ESCUCHA:${NC}"
    netstat -tlnp 2>/dev/null | awk 'NR==1 {print "  " $0} NR>1 && /LISTEN/ {printf "  %-8s %-25s %-20s %s\n", $1, $4, $6, $7}' | head -15
    
    echo -e "\n${BLUE}🔓 Puertos UDP en ESCUCHA:${NC}"
    netstat -ulnp 2>/dev/null | awk 'NR>1 {printf "  %-8s %-25s %-20s %s\n", $1, $4, $5, $6}' | head -10
    
    echo -e "\n${BLUE}📊 Resumen:${NC}"
    echo -e "  Total puertos TCP: $(netstat -tln | grep LISTEN | wc -l)"
    echo -e "  Total puertos UDP: $(netstat -uln | wc -l)"
    
    pause
}

# OPCIÓN 5: Estadísticas de Tráfico de Red
show_statistics() {
    show_banner
    echo -e "${GREEN}═══ ESTADÍSTICAS DE TRÁFICO ═══${NC}\n"
    
    echo -e "${BLUE}📊 Estadísticas por Protocolo:${NC}"
    netstat -s | grep -A 5 "Tcp:\|Udp:\|Ip:" | sed 's/^/  /'
    
    echo -e "\n${BLUE}📈 Tráfico por Interface:${NC}"
    cat /proc/net/dev | awk 'NR>2 {
        iface=$1; 
        gsub(":", "", iface);
        rx_bytes=$2; tx_bytes=$10;
        rx_mb=rx_bytes/1048576; tx_mb=tx_bytes/1048576;
        printf "  %-10s RX: %8.2f MB  |  TX: %8.2f MB\n", iface, rx_mb, tx_mb
    }'
    
    pause
}

# OPCIÓN 6: Verificador de Puertos
check_port() {
    show_banner
    echo -e "${GREEN}═══ VERIFICADOR DE PUERTOS ═══${NC}\n"
    
    echo -e "${BLUE}Ingrese el número de puerto a verificar:${NC}"
    read -p "Puerto: " port
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo -e "${RED}❌ Puerto inválido. Debe ser un número entre 1 y 65535${NC}"
        pause
        return
    fi
    
    echo -e "\n${YELLOW}🔍 Verificando puerto $port...${NC}\n"
    
    # Verificar TCP
    tcp_result=$(netstat -tln | grep ":$port ")
    if [ -n "$tcp_result" ]; then
        echo -e "${GREEN}✅ Puerto $port/TCP está ABIERTO${NC}"
        echo -e "${BLUE}Detalles:${NC}"
        echo "$tcp_result" | sed 's/^/  /'
        
        # Intentar identificar el servicio
        service=$(grep -w "$port/tcp" /etc/services | head -1 | awk '{print $1}')
        if [ -n "$service" ]; then
            echo -e "${BLUE}Servicio conocido:${NC} $service"
        fi
        
        # Intentar obtener el proceso
        process=$(netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}')
        if [ -n "$process" ]; then
            echo -e "${BLUE}Proceso:${NC} $process"
        fi
    else
        echo -e "${RED}❌ Puerto $port/TCP está CERRADO${NC}"
    fi
    
    # Verificar UDP
    udp_result=$(netstat -uln | grep ":$port ")
    if [ -n "$udp_result" ]; then
        echo -e "\n${GREEN}✅ Puerto $port/UDP está ABIERTO${NC}"
        echo -e "${BLUE}Detalles:${NC}"
        echo "$udp_result" | sed 's/^/  /'
        
        service=$(grep -w "$port/udp" /etc/services | head -1 | awk '{print $1}')
        if [ -n "$service" ]; then
            echo -e "${BLUE}Servicio conocido:${NC} $service"
        fi
    fi
    
    # Verificar si está en uso por algún proceso
    if command -v lsof &> /dev/null; then
        lsof_result=$(lsof -i :$port 2>/dev/null)
        if [ -n "$lsof_result" ]; then
            echo -e "\n${BLUE}📋 Información detallada (lsof):${NC}"
            echo "$lsof_result" | sed 's/^/  /'
        fi
    fi
    
    pause
}

# Menú Principal
menu() {
    while true; do
        show_banner
        echo -e "${BLUE}Seleccione una opción:${NC}\n"
        echo -e "  ${GREEN}1)${NC} Ver Interfaces de Red"
        echo -e "  ${GREEN}2)${NC} Ver Conexiones Activas"
        echo -e "  ${GREEN}3)${NC} Ver Tabla de Enrutamiento"
        echo -e "  ${GREEN}4)${NC} Ver Puertos Abiertos y Servicios"
        echo -e "  ${GREEN}5)${NC} Ver Estadísticas de Tráfico"
        echo -e "  ${GREEN}6)${NC} Verificar Puerto Específico"
        echo -e "  ${RED}7)${NC} Salir"
        echo ""
        read -p "Opción [1-7]: " option
        
        case $option in
            1) show_interfaces ;;
            2) show_connections ;;
            3) show_routing ;;
            4) show_ports ;;
            5) show_statistics ;;
            6) check_port ;;
            7) 
                echo -e "\n${CYAN}¡Hasta luego!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}❌ Opción inválida. Intente nuevamente.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Verificar permisos de root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  Advertencia: Algunas funciones requieren permisos de root${NC}"
    echo -e "${YELLOW}   Para información completa, ejecute: sudo $0${NC}\n"
    sleep 2
fi

# Iniciar el menú
menu