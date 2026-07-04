#!/bin/bash

echo "IDENTIFICANDO EL SISTEMA OPERATIVO"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS=$ID
else
    echo "Error: No se pudo determinar el sistema operativo."
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
	audacity
	picard
	easytag
	calibre
	sigil
	gimp
	inkscape
	strawberry
	fastfetch
	papirus-icon-theme
)

APPS_UBUNTU=(
	build-essential
)

APPS_FEDORA=(

)

APPS_ARCH=(

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
			sudo $1 -S flatpak
		fi
	fi
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
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

echo -e "\n\nINSTALANDO APLICACIONES MULTIMEDIA (FLATPAK)\n\n"
flatpak install -y flathub com.usehandbrake.HandBrake
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub com.yacreader.YACReader

configurar_git

agregar_a_archivo "fastfetch" "$HOME/.bashrc"
agregar_a_archivo "alias cls='clear && fastfetch'" "$HOME/.bashrc"


echo -e "\n\nListo, configuracion terminada!!!\n"
