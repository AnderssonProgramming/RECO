#!/bin/bash
# Script de Información de Red para Oracle Solaris
# Laboratorio 8 - RECo
# Escuela Colombiana de Ingeniería Julio Garavito

# Colores para mejor presentación
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
ROJO='\033[0;31m'
NC='\033[0m' # Sin color

# Función para mostrar el encabezado
mostrar_encabezado() {
    clear
    echo -e "${AZUL}========================================${NC}"
    echo -e "${VERDE}  INFORMACIÓN DE RED - ORACLE SOLARIS${NC}"
    echo -e "${AZUL}========================================${NC}"
    echo ""
}

# Función para pausar
pausa() {
    echo ""
    echo -e "${AMARILLO}Presione ENTER para continuar...${NC}"
    read
}

# Opción 1: Mostrar información de interfaces de red
mostrar_interfaces() {
    mostrar_encabezado
    echo -e "${VERDE}=== INTERFACES DE RED CONFIGURADAS ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: ifconfig -a${NC}"
    echo ""
    
    ifconfig -a
    
    echo ""
    echo -e "${VERDE}=== RESUMEN DE INTERFACES ===${NC}"
    echo "Interfaces activas:"
    ifconfig -a | grep "^[a-z]" | awk '{print "  - " $1}' | sed 's/:$//'
    
    pausa
}

# Opción 2: Mostrar estadísticas de red
mostrar_estadisticas() {
    mostrar_encabezado
    echo -e "${VERDE}=== ESTADÍSTICAS DE RED ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: netstat -i${NC}"
    echo ""
    
    netstat -i
    
    echo ""
    echo -e "${VERDE}=== CONEXIONES ACTIVAS ===${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -an | grep ESTABLISHED${NC}"
    echo ""
    
    netstat -an | grep ESTABLISHED | head -10
    TOTAL=$(netstat -an | grep ESTABLISHED | wc -l)
    echo ""
    echo "Total de conexiones establecidas: $TOTAL"
    
    pausa
}

# Opción 3: Mostrar tabla de enrutamiento
mostrar_rutas() {
    mostrar_encabezado
    echo -e "${VERDE}=== TABLA DE ENRUTAMIENTO ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: netstat -rn${NC}"
    echo ""
    
    netstat -rn
    
    echo ""
    echo -e "${VERDE}=== GATEWAY PREDETERMINADO ===${NC}"
    GATEWAY=$(netstat -rn | grep default | awk '{print $2}' | head -1)
    if [ -n "$GATEWAY" ]; then
        echo "Gateway: $GATEWAY"
    else
        echo "No se encontró gateway predeterminado"
    fi
    
    pausa
}

# Opción 4: Mostrar información de datalinks (específico Solaris)
mostrar_datalinks() {
    mostrar_encabezado
    echo -e "${VERDE}=== INFORMACIÓN DE DATALINKS ===${NC}"
    echo ""
    
    # Verificar si dladm está disponible (Solaris 11+)
    if command -v dladm > /dev/null 2>&1; then
        echo -e "${AMARILLO}Comando ejecutado: dladm show-link${NC}"
        echo ""
        dladm show-link
        
        echo ""
        echo -e "${VERDE}=== PROPIEDADES DE DATALINKS ===${NC}"
        echo -e "${AMARILLO}Comando ejecutado: dladm show-linkprop${NC}"
        echo ""
        dladm show-linkprop
    else
        echo -e "${ROJO}El comando dladm no está disponible en esta versión de Solaris${NC}"
        echo ""
        echo "Mostrando información alternativa con ifconfig:"
        ifconfig -a | grep -E "^[a-z]|inet|ether"
    fi
    
    pausa
}

# Opción 5: Mostrar puertos en escucha
mostrar_puertos() {
    mostrar_encabezado
    echo -e "${VERDE}=== PUERTOS EN ESCUCHA ===${NC}"
    echo ""
    echo -e "${AMARILLO}Comando ejecutado: netstat -an | grep LISTEN${NC}"
    echo ""
    
    echo "TCP Ports:"
    netstat -an -P tcp | grep LISTEN | awk '{print $1, $2}' | sort -u
    
    echo ""
    echo "UDP Ports:"
    netstat -an -P udp | grep Idle | head -15
    
    echo ""
    echo -e "${VERDE}=== RESUMEN ===${NC}"
    TCP_COUNT=$(netstat -an -P tcp | grep LISTEN | wc -l)
    UDP_COUNT=$(netstat -an -P udp | wc -l)
    echo "Total puertos TCP en escucha: $TCP_COUNT"
    echo "Total puertos UDP: $UDP_COUNT"
    
    pausa
}

# Opción 6: Información completa del sistema de red
mostrar_info_completa() {
    mostrar_encabezado
    echo -e "${VERDE}=== INFORMACIÓN COMPLETA DEL SISTEMA DE RED ===${NC}"
    echo ""
    
    echo -e "${AZUL}--- Hostname ---${NC}"
    hostname
    
    echo ""
    echo -e "${AZUL}--- Direcciones IP configuradas ---${NC}"
    ifconfig -a | grep "inet " | awk '{print $2}'
    
    echo ""
    echo -e "${AZUL}--- DNS Servers ---${NC}"
    if [ -f /etc/resolv.conf ]; then
        grep nameserver /etc/resolv.conf
    else
        echo "Archivo /etc/resolv.conf no encontrado"
    fi
    
    echo ""
    echo -e "${AZUL}--- Estadísticas de protocolos ---${NC}"
    echo -e "${AMARILLO}Comando ejecutado: netstat -s${NC}"
    echo ""
    netstat -s | head -30
    echo "... (salida truncada)"
    
    pausa
}

# Menú principal
menu_principal() {
    while true; do
        mostrar_encabezado
        echo -e "${AZUL}Seleccione una opción:${NC}"
        echo ""
        echo "  1) Mostrar interfaces de red"
        echo "  2) Mostrar estadísticas de red y conexiones"
        echo "  3) Mostrar tabla de enrutamiento"
        echo "  4) Mostrar datalinks (Solaris 11+)"
        echo "  5) Mostrar puertos en escucha"
        echo "  6) Información completa del sistema de red"
        echo "  7) Salir"
        echo ""
        echo -n "Opción: "
        read opcion
        
        case $opcion in
            1) mostrar_interfaces ;;
            2) mostrar_estadisticas ;;
            3) mostrar_rutas ;;
            4) mostrar_datalinks ;;
            5) mostrar_puertos ;;
            6) mostrar_info_completa ;;
            7) 
                echo ""
                echo -e "${VERDE}¡Hasta pronto!${NC}"
                exit 0
                ;;
            *)
                echo ""
                echo -e "${ROJO}Opción inválida. Por favor intente nuevamente.${NC}"
                sleep 2
                ;;
        esac
    done
}

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${AMARILLO}Advertencia: Algunos comandos pueden requerir privilegios de root${NC}"
    echo -e "${AMARILLO}Para mejor funcionalidad, ejecute como: sudo $0${NC}"
    echo ""
    sleep 2
fi

# Iniciar el menú
menu_principal