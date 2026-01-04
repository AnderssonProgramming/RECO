#!/bin/bash
# Script de Monitoreo de Red - Solaris (Compatible con grep y awk nativos)
# Lab 07 - Redes de Computadores

# Función para el banner
show_banner() {
    clear
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║     MONITOR DE RED - SOLARIS                         ║"
    echo "║     Lab 07 - Infraestructura y Capa de Red           ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo ""
}

# Función para pausar
pause() {
    echo ""
    echo "Presione ENTER para continuar..."
    read dummy
}

# OPCIÓN 1: Información de Interfaces de Red
show_interfaces() {
    show_banner
    echo "═══ INTERFACES DE RED ═══"
    echo ""
    
    echo "📡 Interfaces Configuradas:"
    ifconfig -a | egrep "^[a-z]|inet " | sed 's/^/  /'
    
    echo ""
    echo "📊 Estado de Interfaces:"
    if command -v dladm >/dev/null 2>&1; then
        dladm show-link 2>/dev/null | sed 's/^/  /' || echo "  comando dladm no disponible"
    else
        netstat -i | sed 's/^/  /'
    fi
    
    echo ""
    echo "🔧 Información Detallada de Plumb:"
    # Guardar salida de ifconfig en archivo temporal
    ifconfig -a > /tmp/ifconfig_out_$
    # Leer línea por línea
    current_iface=""
    while IFS= read -r line; do
        # Si la línea empieza con letra (nueva interfaz)
        case "$line" in
            [a-z]*) 
                current_iface=$(echo "$line" | cut -d: -f1)
                ;;
            *inet\ *)
                # Si contiene "inet " pero no "inet6"
                if echo "$line" | grep "inet " | grep -v "inet6" >/dev/null 2>&1; then
                    ip=$(echo "$line" | grep -o "inet [0-9.]*" | cut -d' ' -f2)
                    [ -n "$current_iface" ] && [ -n "$ip" ] && echo "  $current_iface: $ip"
                fi
                ;;
        esac
    done < /tmp/ifconfig_out_$
    rm -f /tmp/ifconfig_out_$
    
    echo ""
    echo "🌐 Direcciones MAC:"
    # Guardar salida de ifconfig en archivo temporal
    ifconfig -a > /tmp/ifconfig_mac_$
    current_iface=""
    while IFS= read -r line; do
        case "$line" in
            [a-z]*) 
                current_iface=$(echo "$line" | cut -d: -f1)
                ;;
            *ether*)
                mac=$(echo "$line" | grep "ether" | head -1 | cut -d' ' -f2)
                [ -n "$current_iface" ] && [ -n "$mac" ] && echo "  $current_iface: $mac"
                ;;
        esac
    done < /tmp/ifconfig_mac_$
    rm -f /tmp/ifconfig_mac_$
    
    pause
}

# OPCIÓN 2: Conexiones de Red Activas
show_connections() {
    show_banner
    echo "═══ CONEXIONES DE RED ACTIVAS ═══"
    echo ""
    
    echo "🔌 Conexiones TCP Establecidas:"
    netstat -an -P tcp | awk '
        $1 ~ /^[0-9]/ && $NF == "ESTABLISHED" {
            printf "  %-25s → %-25s [%s]\n", $1, $2, $NF
        }
    ' | head -20
    
    echo ""
    echo "📈 Estadísticas por Estado:"
    netstat -an -P tcp | awk '
        BEGIN {
            listen=0; established=0; time_wait=0; close_wait=0; fin_wait=0; syn_sent=0; syn_rcvd=0; otros=0
        }
        $NF == "LISTEN" {listen++}
        $NF == "ESTABLISHED" {established++}
        $NF == "TIME_WAIT" {time_wait++}
        $NF == "CLOSE_WAIT" {close_wait++}
        $NF ~ /FIN_WAIT/ {fin_wait++}
        $NF == "SYN_SENT" {syn_sent++}
        $NF == "SYN_RCVD" {syn_rcvd++}
        $NF !~ /(LISTEN|ESTABLISHED|TIME_WAIT|CLOSE_WAIT|FIN_WAIT|SYN_SENT|SYN_RCVD)/ && $NF != "State" {otros++}
        END {
            if (listen > 0) printf "  %-15s: %d conexiones\n", "LISTEN", listen
            if (established > 0) printf "  %-15s: %d conexiones\n", "ESTABLISHED", established
            if (time_wait > 0) printf "  %-15s: %d conexiones\n", "TIME_WAIT", time_wait
            if (close_wait > 0) printf "  %-15s: %d conexiones\n", "CLOSE_WAIT", close_wait
            if (fin_wait > 0) printf "  %-15s: %d conexiones\n", "FIN_WAIT", fin_wait
            if (syn_sent > 0) printf "  %-15s: %d conexiones\n", "SYN_SENT", syn_sent
            if (syn_rcvd > 0) printf "  %-15s: %d conexiones\n", "SYN_RCVD", syn_rcvd
            if (otros > 0) printf "  %-15s: %d conexiones\n", "OTROS", otros
        }
    '
    
    echo ""
    echo "🌐 Top 5 IPs Conectadas:"
    netstat -an -P tcp | awk '
        $NF == "ESTABLISHED" {
            print $2
        }
    ' | awk -F'.' '
        {
            printf "%s.%s.%s.%s\n", $1, $2, $3, $4
        }
    ' | sort | uniq -c | sort -rn | head -5 | awk '
        {
            printf "  %s conexiones desde %s\n", $1, $2
        }
    '
    
    echo ""
    echo "📊 Total de Conexiones:"
    total=$(netstat -an -P tcp | grep -v "Local Address" | grep -v "^$" | wc -l)
    echo "  Total: $total conexiones TCP"
    
    pause
}

# OPCIÓN 3: Tabla de Enrutamiento
show_routing() {
    show_banner
    echo "═══ TABLA DE ENRUTAMIENTO ═══"
    echo ""
    
    echo "🛣️  Rutas IPv4:"
    netstat -rn -f inet | sed 's/^/  /'
    
    echo ""
    echo "📍 Gateway Predeterminado:"
    netstat -rn | awk '
        /default/ {
            printf "  Gateway: %s via %s\n", $2, $6
        }
    '
    
    echo ""
    echo "🔗 Interfaces de Enrutamiento:"
    netstat -rn | awk '
        NR>2 && $1 !~ /Destination/ {
            if ($1 == "default") 
                dest="Default Route"
            else 
                dest=$1
            printf "  %-20s → Gateway: %-15s Interface: %s\n", dest, $2, $6
        }
    ' | head -10
    
    pause
}

# OPCIÓN 4: Puertos Abiertos y Servicios
show_ports() {
    show_banner
    echo "═══ PUERTOS ABIERTOS Y SERVICIOS ═══"
    echo ""
    
    echo "🔓 Puertos TCP en ESCUCHA:"
    netstat -an -P tcp | awk '
        $NF == "LISTEN" {
            n=split($1, parts, ".")
            puerto=parts[n]
            printf "  %-8s %-30s [%s]\n", "TCP", $1, $NF
        }
    ' | head -15
    
    echo ""
    echo "🔓 Puertos UDP Activos:"
    netstat -an -P udp | awk '
        NR>2 && $1 !~ /Local/ {
            printf "  %-8s %-30s\n", "UDP", $1
        }
    ' | head -10
    
    echo ""
    echo "📊 Resumen:"
    tcp_count=$(netstat -an -P tcp | grep LISTEN | wc -l)
    udp_count=$(netstat -an -P udp | awk 'NR>2' | wc -l)
    echo "  Total puertos TCP en escucha: $tcp_count"
    echo "  Total sockets UDP: $udp_count"
    
    echo ""
    echo "🔍 Servicios Comunes Activos:"
    netstat -an -P tcp | awk '
        $NF == "LISTEN" {
            n=split($1, parts, ".")
            puerto=parts[n]
            print puerto
        }
    ' | while read port; do
        case $port in
            21) echo "  Puerto $port: FTP" ;;
            22) echo "  Puerto $port: SSH" ;;
            23) echo "  Puerto $port: Telnet" ;;
            25) echo "  Puerto $port: SMTP" ;;
            53) echo "  Puerto $port: DNS" ;;
            80) echo "  Puerto $port: HTTP" ;;
            110) echo "  Puerto $port: POP3" ;;
            143) echo "  Puerto $port: IMAP" ;;
            443) echo "  Puerto $port: HTTPS" ;;
            445) echo "  Puerto $port: SMB" ;;
            3306) echo "  Puerto $port: MySQL" ;;
            5432) echo "  Puerto $port: PostgreSQL" ;;
            8080) echo "  Puerto $port: HTTP-Alt" ;;
        esac
    done | sort -u | head -10
    
    pause
}

# OPCIÓN 5: Estadísticas de Tráfico de Red
show_statistics() {
    show_banner
    echo "═══ ESTADÍSTICAS DE TRÁFICO ═══"
    echo ""
    
    echo "📊 Estadísticas TCP:"
    netstat -s -P tcp | head -20 | sed 's/^/  /'
    
    echo ""
    echo "📊 Estadísticas UDP:"
    netstat -s -P udp | head -15 | sed 's/^/  /'
    
    echo ""
    echo "📊 Estadísticas IP:"
    netstat -s -P ip | head -15 | sed 's/^/  /'
    
    echo ""
    echo "📈 Tráfico por Interface:"
    if command -v kstat >/dev/null 2>&1; then
        # Usar kstat para estadísticas detalladas
        echo "  Usando kstat para estadísticas detalladas..."
        kstat -p | awk -F: '
            /net:[0-9]+:(e1000g|bge|nxge|igb|ixgbe|net).*rbytes64/ {
                split($0, a, ":")
                iface=a[3]
                split($NF, b, "\t")
                rx[iface]=b[2]/1048576
            }
            /net:[0-9]+:(e1000g|bge|nxge|igb|ixgbe|net).*obytes64/ {
                split($0, a, ":")
                iface=a[3]
                split($NF, b, "\t")
                tx[iface]=b[2]/1048576
            }
            END {
                for (i in rx) {
                    if (tx[i] == "") tx[i]=0
                    printf "  %-10s RX: %10.2f MB  |  TX: %10.2f MB\n", i, rx[i], tx[i]
                }
            }
        ' 2>/dev/null
    fi
    
    # Alternativa con netstat -i
    echo ""
    echo "📊 Estadísticas de Paquetes por Interface:"
    netstat -i | awk '
        NR>1 && $1 !~ /Name/ {
            printf "  %-12s Ipkts: %-10s Opkts: %-10s\n", $1, $5, $7
        }
    '
    
    pause
}

# OPCIÓN 6: Verificador de Puertos
check_port() {
    show_banner
    echo "═══ VERIFICADOR DE PUERTOS ═══"
    echo ""
    
    echo "Ingrese el número de puerto a verificar:"
    read port
    
    # Validar puerto (compatible con Solaris)
    if [ -z "$port" ]; then
        echo "❌ Puerto inválido. No puede estar vacío"
        pause
        return
    fi
    
    # Verificar que sea numérico
    case $port in
        ''|*[!0-9]*)
            echo "❌ Puerto inválido. Debe ser un número"
            pause
            return
            ;;
    esac
    
    if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        echo "❌ Puerto inválido. Debe ser un número entre 1 y 65535"
        pause
        return
    fi
    
    echo ""
    echo "🔍 Verificando puerto $port..."
    echo ""
    
    # Verificar TCP - usando grep y cut en lugar de awk complejo
    tcp_result=$(netstat -an -P tcp | grep LISTEN | grep "\.$port " 2>/dev/null)
    
    if [ -n "$tcp_result" ]; then
        echo "✅ Puerto $port/TCP está ABIERTO"
        echo "Detalles:"
        echo "$tcp_result" | sed 's/^/  /'
        
        # Identificar servicio común
        case $port in
            20) service="FTP Data" ;;
            21) service="FTP Control" ;;
            22) service="SSH" ;;
            23) service="Telnet" ;;
            25) service="SMTP" ;;
            53) service="DNS" ;;
            80) service="HTTP" ;;
            110) service="POP3" ;;
            143) service="IMAP" ;;
            443) service="HTTPS" ;;
            445) service="SMB" ;;
            3306) service="MySQL" ;;
            3389) service="RDP" ;;
            5432) service="PostgreSQL" ;;
            8080) service="HTTP Alternate" ;;
            *) service="" ;;
        esac
        
        if [ -n "$service" ]; then
            echo "Servicio común conocido: $service"
        fi
        
        # Intentar obtener más información del servicio
        service_info=$(grep " $port/tcp" /etc/services 2>/dev/null | head -1 | awk '{print $1}')
        if [ -n "$service_info" ]; then
            echo "Servicio en /etc/services: $service_info"
        fi
    else
        echo "❌ Puerto $port/TCP está CERRADO o no está en LISTEN"
    fi
    
    echo ""
    
    # Verificar UDP - usando grep y cut
    udp_result=$(netstat -an -P udp | grep "\.$port " 2>/dev/null)
    
    if [ -n "$udp_result" ]; then
        echo "✅ Puerto $port/UDP está ABIERTO"
        echo "Detalles:"
        echo "$udp_result" | sed 's/^/  /'
        
        # Identificar servicio UDP común
        case $port in
            53) service="DNS" ;;
            67) service="DHCP Server" ;;
            68) service="DHCP Client" ;;
            69) service="TFTP" ;;
            123) service="NTP" ;;
            161) service="SNMP" ;;
            514) service="Syslog" ;;
            *) service="" ;;
        esac
        
        if [ -n "$service" ]; then
            echo "Servicio UDP conocido: $service"
        fi
        
        service_info=$(grep " $port/udp" /etc/services 2>/dev/null | head -1 | awk '{print $1}')
        if [ -n "$service_info" ]; then
            echo "Servicio en /etc/services: $service_info"
        fi
    else
        echo "ℹ️  Puerto $port/UDP no está en escucha"
    fi
    
    # Información adicional de /etc/services
    echo ""
    echo "📋 Información adicional del puerto $port:"
    port_info=$(grep " $port/" /etc/services 2>/dev/null)
    if [ -n "$port_info" ]; then
        echo "$port_info" | sed 's/^/  /'
    else
        echo "  No se encontró en /etc/services"
    fi
    
    # Intentar obtener procesos (requiere root)
    if [ "$(id -u)" -eq 0 ]; then
        echo ""
        echo "🔎 Buscando procesos asociados..."
        pfiles /proc/*/fd/* 2>/dev/null | grep -B 5 "port: $port" 2>/dev/null | awk '/^[0-9]/ {print "  PID:", $1}' | head -5
    fi
    
    pause
}

# Menú Principal
menu() {
    while true; do
        show_banner
        echo "Seleccione una opción:"
        echo ""
        echo "  1) Ver Interfaces de Red"
        echo "  2) Ver Conexiones Activas"
        echo "  3) Ver Tabla de Enrutamiento"
        echo "  4) Ver Puertos Abiertos y Servicios"
        echo "  5) Ver Estadísticas de Tráfico"
        echo "  6) Verificar Puerto Específico"
        echo "  7) Salir"
        echo ""
        printf "Opción [1-7]: "
        read option
        
        case $option in
            1) show_interfaces ;;
            2) show_connections ;;
            3) show_routing ;;
            4) show_ports ;;
            5) show_statistics ;;
            6) check_port ;;
            7) 
                echo ""
                echo "¡Hasta luego!"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo "❌ Opción inválida. Intente nuevamente."
                sleep 2
                ;;
        esac
    done
}

# Verificar permisos de root
if [ "$(id -u)" -ne 0 ]; then 
    echo "⚠️  Advertencia: Algunas funciones requieren permisos de root"
    echo "   Para información completa, ejecute: pfexec $0"
    echo ""
    sleep 2
fi

# Iniciar el menú
menu