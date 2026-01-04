#!/bin/bash
# Script de Informacion de Red para Slackware Linux
# Laboratorio 8 - RECo
# Escuela Colombiana de Ingenieria Julio Garavito

# Colores para mejor presentacion
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # Sin color

# Funcion para mostrar el encabezado
mostrar_encabezado() {
    clear
    echo -e "${AZUL}========================================${NC}"
    echo -e "${VERDE}  INFORMACION DE RED - SLACKWARE LINUX${NC}"
    echo -e "${AZUL}========================================${NC}"
    echo ""
}

# Funcion para pausar
pausa() {
    echo ""
    echo -e "${AMARILLO}Presione ENTER para continuar...${NC}"
    read
}

# Opcion 1: Mostrar informacion de interfaces de red
mostrar_interfaces() {
    mostrar_encabezado
    echo -e "${VERDE}=== INTERFACES DE RED CONFIGURADAS ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: ifconfig -a${NC}"
    echo ""
    
    ifconfig -a
    
    echo ""
    echo -e "${VERDE}=== RESUMEN DE INTERFACES ===${NC}"
    echo "Interfaces disponibles:"
    ifconfig -a | grep "^[a-z]" | awk '{print "  - " $1}' | sed 's/:$//'
    
    echo ""
    echo -e "${VERDE}=== INTERFACES ACTIVAS (UP) ===${NC}"
    ifconfig | grep "^[a-z]" | awk '{print "  - " $1}' | sed 's/:$//'
    
    pausa
}

# Opcion 2: Mostrar estadisticas de red con netstat
mostrar_estadisticas() {
    mostrar_encabezado
    echo -e "${VERDE}=== ESTADISTICAS DE RED ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: netstat -i${NC}"
    echo ""
    
    netstat -i
    
    echo ""
    echo -e "${VERDE}=== CONEXIONES ACTIVAS ===${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -tuln | grep ESTABLISHED${NC}"
    echo ""
    
    netstat -tun | grep ESTABLISHED | head -15
    TOTAL=$(netstat -tun | grep ESTABLISHED | wc -l)
    echo ""
    echo "Total de conexiones establecidas: $TOTAL"
    
    echo ""
    echo -e "${VERDE}=== ESTADISTICAS POR PROTOCOLO ===${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -s${NC}"
    echo ""
    netstat -s | head -40
    echo "... (salida truncada)"
    
    pausa
}

# Opcion 3: Mostrar tabla de enrutamiento
mostrar_rutas() {
    mostrar_encabezado
    echo -e "${VERDE}=== TABLA DE ENRUTAMIENTO ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: route -n${NC}"
    echo ""
    
    route -n
    
    echo ""
    echo -e "${VERDE}=== GATEWAY PREDETERMINADO ===${NC}"
    GATEWAY=$(route -n | grep "^0.0.0.0" | awk '{print $2}')
    IFACE=$(route -n | grep "^0.0.0.0" | awk '{print $8}')
    if [ -n "$GATEWAY" ]; then
        echo "Gateway: $GATEWAY"
        echo "Interfaz: $IFACE"
    else
        echo "No se encontro gateway predeterminado"
    fi
    
    echo ""
    echo -e "${AMARILLO}Alternativa: ip route show${NC}"
    echo ""
    ip route show
    
    pausa
}

# Opcion 4: Informacion detallada con ethtool
mostrar_ethtool() {
    mostrar_encabezado
    echo -e "${VERDE}=== INFORMACION DETALLADA DE INTERFACES (ethtool) ===${NC}"
    echo ""
    
    # Verificar si ethtool esta instalado
    if ! command -v ethtool &> /dev/null; then
        echo -e "${ROJO}ethtool no esta instalado${NC}"
        echo "Para instalarlo en Slackware: slackpkg install ethtool"
        pausa
        return
    fi
    
    # Obtener interfaces activas
    INTERFACES=$(ifconfig | grep "^[a-z]" | awk '{print $1}' | sed 's/:$//')
    
    for iface in $INTERFACES; do
        # Saltar loopback
        if [ "$iface" = "lo" ]; then
            continue
        fi
        
        echo -e "${CYAN}--- Interfaz: $iface ---${NC}"
        echo ""
        
        # Informacion basica
        echo -e "${AMARILLO}Comando ejecutado: ethtool $iface${NC}"
        echo ""
        ethtool $iface 2>/dev/null
        
        echo ""
        echo -e "${AMARILLO}Estadisticas: ethtool -S $iface${NC}"
        echo ""
        ethtool -S $iface 2>/dev/null | head -20
        echo "... (salida truncada)"
        
        echo ""
        echo "=========================================="
        echo ""
    done
    
    pausa
}

# Opcion 5: Estadisticas de trafico con vnstat
mostrar_vnstat() {
    mostrar_encabezado
    echo -e "${VERDE}=== ESTADISTICAS DE TRAFICO (vnstat) ===${NC}"
    echo ""
    
    # Verificar si vnstat esta instalado
    if ! command -v vnstat &> /dev/null; then
        echo -e "${ROJO}vnstat no esta instalado${NC}"
        echo "Para instalarlo en Slackware:"
        echo "  1. Descarga desde: https://humdi.net/vnstat/"
        echo "  2. O busca en SlackBuilds: https://slackbuilds.org/"
        echo ""
        echo "Mostrando estadisticas alternativas con ifconfig:"
        echo ""
        ifconfig | grep -E "RX packets|TX packets"
        pausa
        return
    fi
    
    # Obtener interfaz principal (primera que no sea lo)
    MAIN_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [ -z "$MAIN_IFACE" ]; then
        MAIN_IFACE=$(ifconfig | grep "^[a-z]" | grep -v "^lo" | head -1 | awk '{print $1}' | sed 's/:$//')
    fi
    
    echo -e "${AMARILLO}Interfaz principal detectada: $MAIN_IFACE${NC}"
    echo ""
    
    # Resumen general
    echo -e "${CYAN}--- Resumen General ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: vnstat -i $MAIN_IFACE${NC}"
    echo ""
    vnstat -i $MAIN_IFACE
    
    echo ""
    echo -e "${CYAN}--- Estadisticas por Hora ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: vnstat -i $MAIN_IFACE -h${NC}"
    echo ""
    vnstat -i $MAIN_IFACE -h
    
    echo ""
    echo -e "${CYAN}--- Estadisticas Diarias ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: vnstat -i $MAIN_IFACE -d${NC}"
    echo ""
    vnstat -i $MAIN_IFACE -d | head -15
    
    pausa
}

# Opcion 6: Mostrar puertos en escucha
mostrar_puertos() {
    mostrar_encabezado
    echo -e "${VERDE}=== PUERTOS EN ESCUCHA ===${NC}"
    echo ""
    
    echo -e "${CYAN}--- Puertos TCP en Escucha ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -tlnp${NC}"
    echo ""
    
    if [ "$(id -u)" -eq 0 ]; then
        netstat -tlnp | grep LISTEN
    else
        netstat -tln | grep LISTEN
        echo ""
        echo -e "${AMARILLO}Nota: Ejecuta como root para ver los procesos asociados${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}--- Puertos UDP en Escucha ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -ulnp${NC}"
    echo ""
    
    if [ "$(id -u)" -eq 0 ]; then
        netstat -ulnp | head -20
    else
        netstat -uln | head -20
        echo ""
        echo -e "${AMARILLO}Nota: Ejecuta como root para ver los procesos asociados${NC}"
    fi
    
    echo ""
    echo -e "${VERDE}=== RESUMEN ===${NC}"
    TCP_COUNT=$(netstat -tln | grep LISTEN | wc -l)
    UDP_COUNT=$(netstat -uln | wc -l)
    echo "Total puertos TCP en escucha: $TCP_COUNT"
    echo "Total puertos UDP: $UDP_COUNT"
    
    echo ""
    echo -e "${CYAN}--- Alternativa con ss ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: ss -tlnp${NC}"
    echo ""
    if command -v ss &> /dev/null; then
        if [ "$(id -u)" -eq 0 ]; then
            ss -tlnp | head -15
        else
            ss -tln | head -15
        fi
    else
        echo "Comando ss no disponible"
    fi
    
    pausa
}

# Opcion 7: Informacion completa del sistema de red
mostrar_info_completa() {
    mostrar_encabezado
    echo -e "${VERDE}=== INFORMACION COMPLETA DEL SISTEMA DE RED ===${NC}"
    echo ""
    
    echo -e "${CYAN}--- Hostname y DNS ---${NC}"
    echo "Hostname: $(hostname)"
    echo "FQDN: $(hostname -f 2>/dev/null || echo 'No configurado')"
    echo ""
    echo "Servidores DNS:"
    if [ -f /etc/resolv.conf ]; then
        grep nameserver /etc/resolv.conf
    else
        echo "Archivo /etc/resolv.conf no encontrado"
    fi
    
    echo ""
    echo -e "${CYAN}--- Direcciones IP Configuradas ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: ip addr show${NC}"
    echo ""
    ip addr show
    
    echo ""
    echo -e "${CYAN}--- Tabla ARP ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: arp -n${NC}"
    echo ""
    arp -n
    
    echo ""
    echo -e "${CYAN}--- Conexiones de Red Activas ---${NC}"
    ESTABLISHED=$(netstat -tun | grep ESTABLISHED | wc -l)
    LISTENING=$(netstat -tln | grep LISTEN | wc -l)
    echo "Conexiones establecidas: $ESTABLISHED"
    echo "Puertos en escucha: $LISTENING"
    
    echo ""
    echo -e "${CYAN}--- Estado del Firewall (iptables) ---${NC}"
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${AMARILLO}Comando ejecutado: iptables -L -n -v${NC}"
        echo ""
        iptables -L -n -v | head -20
        echo "... (salida truncada)"
    else
        echo -e "${AMARILLO}Se requieren privilegios de root para ver iptables${NC}"
    fi
    
    pausa
}

# Opcion 8: Diagnostico de conectividad
mostrar_diagnostico() {
    mostrar_encabezado
    echo -e "${VERDE}=== DIAGNOSTICO DE CONECTIVIDAD ===${NC}"
    echo ""
    
    echo -e "${CYAN}--- Test de Conectividad Local ---${NC}"
    echo "Ping a localhost:"
    ping -c 3 127.0.0.1
    
    echo ""
    echo -e "${CYAN}--- Test de Conectividad a Gateway ---${NC}"
    GATEWAY=$(route -n | grep "^0.0.0.0" | awk '{print $2}' | head -1)
    if [ -n "$GATEWAY" ]; then
        echo "Ping a gateway ($GATEWAY):"
        ping -c 3 $GATEWAY
    else
        echo "No se encontro gateway para probar"
    fi
    
    echo ""
    echo -e "${CYAN}--- Test de Conectividad a Internet ---${NC}"
    echo "Ping a 8.8.8.8 (Google DNS):"
    ping -c 3 8.8.8.8
    
    echo ""
    echo -e "${CYAN}--- Test de Resolucion DNS ---${NC}"
    echo "nslookup google.com:"
    nslookup google.com
    
    echo ""
    echo -e "${CYAN}--- Traceroute a Google ---${NC}"
    if command -v traceroute &> /dev/null; then
        echo "traceroute -m 10 google.com:"
        traceroute -m 10 google.com
    else
        echo "traceroute no esta instalado"
    fi
    
    pausa
}

# Menu principal
menu_principal() {
    while true; do
        mostrar_encabezado
        echo -e "${AZUL}Seleccione una opcion:${NC}"
        echo ""
        echo "  1) Mostrar interfaces de red (ifconfig)"
        echo "  2) Mostrar estadisticas de red (netstat)"
        echo "  3) Mostrar tabla de enrutamiento (route)"
        echo "  4) Informacion detallada de interfaces (ethtool)"
        echo "  5) Estadisticas de trafico (vnstat)"
        echo "  6) Mostrar puertos en escucha"
        echo "  7) Informacion completa del sistema de red"
        echo "  8) Diagnostico de conectividad"
        echo "  9) Salir"
        echo ""
        echo -n "Opcion: "
        read opcion
        
        case $opcion in
            1) mostrar_interfaces ;;
            2) mostrar_estadisticas ;;
            3) mostrar_rutas ;;
            4) mostrar_ethtool ;;
            5) mostrar_vnstat ;;
            6) mostrar_puertos ;;
            7) mostrar_info_completa ;;
            8) mostrar_diagnostico ;;
            9) 
                echo ""
                echo -e "${VERDE}Hasta pronto!${NC}"
                exit 0
                ;;
            *)
                echo ""
                echo -e "${ROJO}Opcion invalida. Por favor intente nuevamente.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${AMARILLO}Advertencia: Este script no se esta ejecutando como root${NC}"
    echo -e "${AMARILLO}Algunas funciones pueden estar limitadas${NC}"
    echo -e "${AMARILLO}Para mejor funcionalidad, ejecute como: sudo $0${NC}"
    echo ""
    sleep 2
fi

# Iniciar el menu
menu_principal