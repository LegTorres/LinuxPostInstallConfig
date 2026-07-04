#!/bin/bash

echo "     IDENTIFICANDO EL SISTEMA OPERATIVO"

if [ -f /etc/os-release ]; then
    source /etc/os-release
    OS=$ID
else
    echo "Error: No se pudo determinar el sistema operativo."
    exit 1
fi

# Convirtiendo el nombre mostrado en el banner a mayusculas.
OS_NAME=$(echo "$OS" | tr '[:lower:]' '[:upper:]')

echo "CONFIGURACION POST INSTALACION DE $OS_NAME LINUX"





case "$OS_NAME" in
	ubuntu|debian|linuxmint|pop|zorin)
	
	;;
	
	fedora)
	
	;;
	arch|manjaro|cachyos)
	
	;;
	





# Mostrar el menú en pantalla
echo "========================================="
echo "             MENÚ DE OPCIONES            "
echo "========================================="
echo "1) Actualizar sistema"
echo "2) Limpiar caché"
echo "3) Ver espacio en disco"
echo "4) Salir"
echo "========================================="
echo "Introduce los números separados por espacios (ej: 1 3):"

# Leer la entrada del usuario en una variable
read -r selecciones

# Procesar cada número introducido
for seleccion in $selecciones; do
    case "$seleccion" in
        1)
            echo -e "\n[*] Ejecutando: Actualizar sistema..."
            # Tu comando aquí
            ;;
        2)
            echo -e "\n[*] Ejecutando: Limpiar caché..."
            # Tu comando aquí
            ;;
        3)
            echo -e "\n[*] Ejecutando: Ver espacio en disco..."
            df -h
            ;;
        4)
            echo -e "\n[*] Ejecutando: Reiniciar servicios..."
            # Tu comando aquí
            exit 0
            ;;
        *)
            echo -e "\n[!] Opción '$seleccion' no es válida. Saltando..."
            ;;
    esac
done

echo -e "\n¡Proceso finalizado!"
# ==============================================================================
# 2. INSTALACIÓN DE REPOSITORIOS Y PAQUETES SEGÚN LA DISTRIBUCIÓN
# ==============================================================================
case "$OS" in
    fedora)
        # 1. ACTUALIZANDO EL SISTEMA
        echo -e "\n\nACTUALIZANDO EL SISTEMA (DNF)\n\n"
        sudo dnf -y update

        # CONFIGURANDO REPOSITORIO DE BRAVE BROWSER
        echo -e "\n\nCONFIGURANDO REPOSITORIO DE BRAVE BROWSER\n\n"
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

        # CONFIGURACIÓN DE FLATPAK Y FLATHUB
        echo -e "\n\nCONFIGURANDO FLATPAK Y REPOSITORIO FLATHUB\n\n"
        sudo dnf install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

        # 2. INSTALANDO APLICACIONES DE USO GENERAL (DNF + FLATPAK)
        echo -e "\n\nINSTALANDO APLICACIONES NATIVAS (DNF)\n\n"
        sudo dnf install -y zsh vim yt-dlp tilix gimp audacity picard easytag calibre sigil strawberry gapless brave-browser fastfetch btop htop papirus-icon-theme qt6ct qt5ct kvantum gnome-tweaks git

        # 3. INSTALANDO HERRAMIENTAS DE DESARROLLO (Sintaxis @ para DNF5)
        echo -e "\n\nINSTALANDO HERRAMIENTAS DE DESARROLLO (DNF5)\n\n"
        sudo dnf install -y @development-tools @development-libraries
        ;;

    ubuntu|debian|linuxmint|pop)
        # 1. ACTUALIZANDO EL SISTEMA
        echo -e "\n\nACTUALIZANDO EL SISTEMA (APT)\n\n"
        sudo apt update && sudo apt upgrade -y

        # CONFIGURANDO REPOSITORIO DE BRAVE BROWSER
        echo -e "\n\nCONFIGURANDO REPOSITORIO DE BRAVE BROWSER\n\n"
        sudo apt install -y curl
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-rpm-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.p/brave-browser-release.list
        sudo apt update

        # CONFIGURACIÓN DE FLATPAK Y FLATHUB
        echo -e "\n\nCONFIGURANDO FLATPAK Y REPOSITORIO FLATHUB\n\n"
        sudo apt install -y flatpak
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

        # 2. INSTALANDO APLICACIONES DE USO GENERAL (APT)
        echo -e "\n\nINSTALANDO APLICACIONES NATIVAS (APT)\n\n"
        sudo apt install -y zsh vim yt-dlp tilix audacity picard easytag calibre sigil strawberry brave-browser fastfetch btop htop papirus-icon-theme qt6ct qt5ct qt5-style-kvantum qt6-style-kvantum python3-pip python3-venv qt6-base-dev qt6-tools-dev


        # 3. INSTALANDO HERRAMIENTAS DE DESARROLLO (Equivalente en APT)
        echo -e "\n\nINSTALANDO HERRAMIENTAS DE DESARROLLO (APT)\n\n"
        sudo apt install -y build-essential
        
        # 1. Crea una carpeta para tus proyectos de Qt y entra en ella
		mkdir -p ~/Proyectos/proyectos_qt && cd ~/Proyectos/proyectos_qt

		# 2. Crea el entorno virtual llamado 'env'
		python3 -m venv env

		# 3. ACTIVA el entorno virtual (Debes hacer esto CADA VEZ que vayas a programar)
		source env/bin/activate
		
		pip install PySide6
		pip install -U pyinstaller
		
		cat << 'EOF' > ~/.local/share/applications/designer.desktop
		[Desktop Entry]
		Version=1.0
		Name=Qt Designer 6
		Comment=Diseñador Visual de Interfaces Qt6
		Exec=/usr/lib/qt6/bin/designer
		Icon=/home/edgar/.local/share/icons/qt-designer.png
		Terminal=false
		Type=Application
		Categories=Development;GUIDesigner;
		EOF

        ;;

    *)
        echo -e "\n\e[1;31mLo siento, este script no está optimizado para la distribución: $OS\e[0m\n"
        exit 1
        ;;
esac

# ==============================================================================
# 3. INSTALACIÓN DE APLICACIONES MULTIMEDIA UNIVERSALES (FLATPAK)
# ==============================================================================
echo -e "\n\nINSTALANDO APLICACIONES MULTIMEDIA (FLATPAK)\n\n"
flatpak install -y flathub com.usehandbrake.HandBrake
flatpak install -y flathub org.onlyoffice.desktopeditors
flatpak install -y flathub com.brave.Browser

# ==============================================================================
# 4. CONFIGURACIÓN UNIVERSAL (GIT, SSH, SHELL, ALIAS)
# ==============================================================================

# CONFIGURANDO GIT
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

# Cambiar la shell por defecto de manera segura
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s $(which zsh) $USER
fi

# CREANDO EL ALIAS 'remoto' Y AGREGANDO FASTFETCH (Sin duplicar)
echo -e "CONFIGURANDO ALIAS Y FASTFETCH\n\n"

agregar_si_no_existe() {
    local linea="$1"
    local archivo="$2"
    grep -qF "$linea" "$archivo" 2>/dev/null || echo "$linea" >> "$archivo"
}

# Configuración para Bash
agregar_si_no_existe "alias remoto='eval \$(ssh-agent -s) && ssh-add \$HOME/.ssh/id_ed25519'" "$HOME/.bashrc"
agregar_si_no_existe "fastfetch" "$HOME/.bashrc"
agregar_si_no_existe "alias cls='clear && fastfetch'" "$HOME/.bashrc"
agregar_si_no_existe "alias activa_qt='cd ~/Proyectos/proyectos_qt && source env/bin/activate'" "$HOME/.bashrc" 

# Configuración para Zsh
agregar_si_no_existe "alias remoto='eval \$(ssh-agent -s) && ssh-add \$HOME/.ssh/id_ed25519'" "$HOME/.zshrc"
agregar_si_no_existe "fastfetch" "$HOME/.zshrc"

echo -e "\n\nListo, configuracion terminada!!!\n"
