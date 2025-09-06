#!/bin/bash
# check_servicios.sh

# Colores
verde="\e[32m"
rojo="\e[31m"
azul="\e[34m"
gris="\e[90m"
reset="\e[0m"

# Lista de servicios a chequear
servicios=(
    sshd.service
    #Anade tus servicios aqui
)

opcion=$1

menu(){
    clear
    echo "=== Services App ==="
    echo "1) List of services"
    echo "2) See details of a service"
    echo "3) Add a service"
    echo "q) Exit"
}

exec_option(){
    case $1 in 
        1) listar_servicios; read -p "Press Enter to return to menu" ;;
        2) detalles_servicios ;;
        3) echo "TODO" ;;
        q) exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
}

estado_color() {
    local est=$1
    if [ "$est" = "active" ]; then
        echo -e "${verde}$est${reset}"
    else
        echo -e "${rojo}$est${reset}"
    fi
}

listar_servicios() {
    echo -e "${azul}=== Chequeo de servicios definidos ===${reset}"
    printf "%-25s %-10s %-60s\n" "Servicio" "Estado" "Descripción"
    printf "%.0s-" {1..100}; echo
    i=1
    for service in "${servicios[@]}"; do
        printf "%s) " "$i"
        if systemctl list-unit-files "$service" &>/dev/null; then
            estado=$(systemctl is-active "$service" 2>/dev/null)
            desc=$(systemctl show -p Description "$service" 2>/dev/null | cut -d= -f2)
            printf "%-25s %-20s %-60s\n" "$service" "$(estado_color "$estado")" "$desc"
        else
            printf "%-25s %-20s %-60s\n" "$service" "$(estado_color not-found)" "-"
        fi
        ((i++))
    done
}

detalles_servicios() {
    listar_servicios
    echo
    read -p "Número del servicio para ver detalles: " num
    service="${servicios[num-1]}"
    if [ -z "$service" ]; then
        echo "Selección inválida"
        read -p "Presiona Enter para volver al menú"
        return
    fi
    clear
    echo -e "${azul}=== Detalles de $service ===${reset}"
    systemctl status "$service" --no-pager
    echo
    echo -e "${gris}Últimos 5 logs:${reset}"
    journalctl -u "$service" -n 5 --no-pager
    echo
    read -p "Presiona Enter para volver al menú"
}

# Main
if [ -n "$opcion" ]; then
    exec_option "$opcion"
    exit 0
fi

while true; do
    menu
    read -p "Select an option: " eleccion
    exec_option "$eleccion"
done

