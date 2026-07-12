#!/bin/bash

echo "IDENTIFICANDO EL SISTEMA OPERATIVO"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS=$ID
else
    echo "Error: No se pudo determinar el sistema operativo."
    exit 1
fi

# Guardar el nombre del usuario real que ejecuta el script
REAL_USER=${SUDO_USER:-$USER}

# Si el script se ejecutó directamente con sudo, detenerlo por seguridad
if [ "$EUID" -eq 0 ]; then
    echo -e "\n\033[1;31mError: No ejecutes este script como ROOT directo (su o sudo ./script.sh).\033[0m"
    echo "Ejecútalo como usuario normal: ./script.sh"
    exit 1
fi

echo "CONFIGURACION POST INSTALACION DE $(echo $OS | tr '[:lower:]' '[:upper:]') LINUX"


# ========================================================
# DECLARACION DE VARIABLES
# ========================================================


APPS_UNIVERSALES=(
	git
	vim
	btop
	htop
	curl
	wget
	tilix
	geany
	audacity
	picard
	easytag
	calibre
	sigil
	gimp
	inkscape
	papirus-icon-theme
	strawberry
	qt-creator

)

APPS_UBUNTU=(
	python3-pip
	python3-venv
	qt6-tools-dev 
	qt6-base-dev
	build-essential
)

APPS_FEDORA=(
	python3-pip
	qt6-designer
	qt6-base-devel
	qt6-tools-devel
	fastfetch
	yt-dlp
)

APPS_ARCH=(
	base-devel
	cmake
	python-pip
	qt6-base
	qt6-tools
	fastfetch
	yt-dlp
)

APPS_FLATPAK=(
	com.usehandbrake.HandBrake
	org.onlyoffice.desktopeditors
	com.brave.Browser
	com.yacreader.YACReader
)

APPS_SNAP=(
	fastfetch
	yt-dlp
)


# ========================================================
# AREA DE FUNCIONES
# ========================================================


instalar_flatpak(){
	echo -e "\n\nCONFIGURANDO FLATPAK Y REPOSITORIO FLATHUB\n\n"
	if ! command -v flatpak &> /dev/null; then
		if [ "$1" != "pacman" ]; then
			sudo $1 install -y flatpak
		else
			sudo $1 -S --noconfirm flatpak
		fi
	fi
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
}


instalar_por_entorno() {
    # 1. Detectar el entorno de escritorio y convertirlo a minúsculas
    local desktop=$(echo "${XDG_CURRENT_DESKTOP:-Desconocido}" | tr '[:upper:]' '[:lower:]')
    
    # 2. Detectar el gestor de paquetes disponible en el sistema
    local install_cmd=""
    if command -v apt &> /dev/null; then
        install_cmd="sudo apt install -y"
    elif command -v pacman &> /dev/null; then
        install_cmd="sudo pacman -S --noconfirm"
    elif command -v dnf &> /dev/null; then
        install_cmd="sudo dnf install -y"
    else
        echo "Error: No se encontró un gestor de paquetes compatible (APT, Pacman, DNF)."
        return 1
    fi

    echo "Entorno detectado: $XDG_CURRENT_DESKTOP"

    # 3. Evaluar el entorno e instalar las herramientas específicas
    case "$desktop" in
        *gnome*)
            echo "Configurando herramientas para GNOME..."
            $install_cmd gnome-tweaks gnome-shell-extension-manager
            ;;
        *kde*)
            echo "Configurando herramientas para KDE Plasma..."
            $install_cmd kde-spectacle plasma-widgets-addons
            ;;
        *xfce*)
            echo "Configurando herramientas para XFCE..."
            $install_cmd xfce4-goodies xfce4-whiskermenu-plugin
            ;;
		*cinnamon*)
			$install_cmd cinnamon-spices-updater plank
			;;
        *)
            echo "El entorno '$XDG_CURRENT_DESKTOP' no requiere aplicaciones específicas."
            ;;
    esac
}


agregar_a_archivo(){
	local linea="$1"
    local archivo="$2"
    grep -qF "$linea" "$archivo" 2>/dev/null || echo "$linea" >> "$archivo"
}


configurar_git(){
	echo -e "\n\nCONFIGURANDO GIT\nEstableciendo el nombre de la rama principal a main"
	git config --global init.defaultBranch main

	# Creando ciclo while que se ejecute mientras usuario y email esten vacios (-z "su longitud sea cero")
	read -p "Ingrese su nombre de USUARIO: " gitUser
	while [[ -z "$gitUser" ]]; do
		read -p "El usuario no puede estar vacío. Ingrese su USUARIO: " gitUser
	done
	git config --global user.name "$gitUser"

	read -p "Ingrese su EMAIL: " gitEmail
	while [[ -z "$gitEmail" ]]; do
		read -p "El email no puede estar vacío. Ingrese su EMAIL: " gitEmail
	done
	git config --global user.email "$gitEmail"

	# GENERANDO CLAVE SSH
	echo -e "\n\nGENERANDO CLAVE SSH\n\n"
	if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
		ssh-keygen -t ed25519 -C "$gitEmail" -f "$HOME/.ssh/id_ed25519" -N ""
	fi
	eval "$(ssh-agent -s)"
	ssh-add "$HOME/.ssh/id_ed25519"

	# CREANDO ALIAS PARA LLAMARLO EN CASO DE QUE LA CONEXION NO SE REALICE AUTOMATICAMENTE
	agregar_a_archivo "alias remoto='eval \$(ssh-agent -s) && ssh-add \$HOME/.ssh/id_ed25519'" "$HOME/.bashrc"
}

cambiar_shell(){
	if [ "$SHELL" != "$(which $1)" ]; then
		sudo chsh -s $(which $1) $USER
	fi
}


# ========================================================
# EJECUCION DEL SCRIPT
# ========================================================


case "$OS" in
	ubuntu|debian|linuxmint|pop|zorin)
		echo "Actualizando el sistema:"
		sudo apt update && sudo apt upgrade -y
		echo -e "Instalando las aplicaiones."
		sudo apt install -y "${APPS_UNIVERSALES[@]}" "${APPS_UBUNTU[@]}"
		instalar_flatpak apt
		sudo snap install "${APPS_SNAP[@]}"
		;;
	
	fedora)
		echo "Actualizando el sistema:"
		sudo dnf -y update
		echo -e "Instalando las aplicaiones."
		sudo dnf install -y "${APPS_UNIVERSALES[@]}" "${APPS_FEDORA[@]}"
		instalar_flatpak dnf
		;;

	arch|manjaro|cachyos)
		echo "Actualizando el sistema:"
		if command -v pacman-mirrors &> /dev/null; then
			sudo pacman-mirrors --fasttrack 10
		fi
		sudo pacman -Syyu --noconfirm
		sudo pacman -S --noconfirm "${APPS_UNIVERSALES[@]}" "${APPS_ARCH[@]}"
		instalar_flatpak pacman
		;;

	*)
		echo -e "\n\033[1;31mLo siento, este script no está optimizado para la distribución: $OS\033[0m\n"
		exit 1
		;;
	
esac

mkdir -p ~/Proyectos/proyectos_qt
cd ~/Proyectos/proyectos_qt/
python3 -m venv env
source env/bin/activate
pip install --upgrade pip
pip install PySide6 pyinstaller -U
deactivate
cd ~

echo -e "\n\nINSTALANDO APLICACIONES FLATPAK\n\n"
for app in "${APPS_FLATPAK[@]}"; do
	flatpak install --user -y flathub "$app" || echo "Advertencia: No se pudo instalar $app, continuando..."
done

instalar_por_entorno

configurar_git

echo -e "\n\nCONFIGURANDO ARCHIVO '.vimrc'\n\n"
echo -e "set number\nsyntax on\nset ts=4\nset background=dark\nset autoindent" >> ~/.vimrc

agregar_a_archivo "fastfetch" "$HOME/.bashrc"
agregar_a_archivo "alias cls='clear && fastfetch'" "$HOME/.bashrc"
agregar_a_archivo "alias activar_qt='cd ~/Proyectos/proyectos_qt && source env/bin/activate'" "$HOME/.bashrc"
agregar_a_archivo "alias designer='activar_qt && pyside6-designer'" "$HOME/.bashrc"

echo -e "\n\nListo, configuracion terminada!!!\n"