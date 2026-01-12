#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Development Environment Setup - PHP, Docker, VS Code, Teams, Postman #

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_dev_environment.log"

clear

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║     SETUP NOBARA LINUX - AMBIENTE DE DESENVOLVIMENTO     ║
║                   PHP | Docker | Web Dev                  ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${RESET}"

printf "${NOTE} Iniciando configuração do ambiente de desenvolvimento...\n" 2>&1 | tee -a "$LOG"
sleep 2

# =============================================================================
# 1. ATUALIZAR SISTEMA
# =============================================================================
printf "${NOTE} Atualizando sistema...\n" 2>&1 | tee -a "$LOG"
sudo dnf update -y 2>&1 | tee -a "$LOG"
printf "${OK} Sistema atualizado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 2. INSTALAR VS CODE
# =============================================================================
printf "${NOTE} Instalando VS Code...\n" 2>&1 | tee -a "$LOG"

# Importar chave GPG
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>&1 | tee -a "$LOG"

# Adicionar repositório
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' 2>&1 | tee -a "$LOG"

# Instalar
sudo dnf install code -y 2>&1 | tee -a "$LOG"
printf "${OK} VS Code instalado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 3. INSTALAR DEPENDÊNCIAS PARA PHP
# =============================================================================
printf "${NOTE} Instalando dependências para compilação do PHP...\n" 2>&1 | tee -a "$LOG"

sudo dnf install -y \
    autoconf automake bison gcc gcc-c++ make \
    libxml2-devel openssl-devel libcurl-devel \
    libjpeg-devel libpng-devel libzip-devel \
    bzip2-devel libicu-devel oniguruma-devel \
    readline-devel sqlite-devel re2c libsodium-devel \
    gd-devel libwebp-devel libavif-devel freetype-devel \
    libpq-devel postgresql-devel mysql-devel 2>&1 | tee -a "$LOG"

printf "${OK} Dependências do PHP instaladas\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 4. INSTALAR MISE
# =============================================================================
printf "${NOTE} Instalando Mise (gerenciador de versões)...\n" 2>&1 | tee -a "$LOG"

curl https://mise.run | sh 2>&1 | tee -a "$LOG"

# Detectar shell do usuário
SHELL_NAME=$(basename "$SHELL")
SHELL_RC=""

case "$SHELL_NAME" in
    bash)
        SHELL_RC="$HOME/.bashrc"
        ;;
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    *)
        printf "${WARN} Shell não reconhecido: $SHELL_NAME. Configure manualmente.\n" 2>&1 | tee -a "$LOG"
        SHELL_RC="$HOME/.bashrc"
        ;;
esac

# Adicionar mise ao shell se ainda não estiver
if ! grep -q "mise activate" "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# Mise - gerenciador de versões' >> "$SHELL_RC"
    echo 'eval "$(~/.local/bin/mise activate '$SHELL_NAME')"' >> "$SHELL_RC"
    printf "${OK} Mise adicionado ao $SHELL_RC\n" 2>&1 | tee -a "$LOG"
else
    printf "${WARN} Mise já está configurado no $SHELL_RC\n" 2>&1 | tee -a "$LOG"
fi

# Ativar mise na sessão atual
export PATH="$HOME/.local/bin:$PATH"
eval "$(~/.local/bin/mise activate $SHELL_NAME)" 2>&1 | tee -a "$LOG"

printf "${OK} Mise instalado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 5. INSTALAR PHP VIA MISE
# =============================================================================
printf "${NOTE} Instalando PHP 8.3 via Mise (isso pode demorar alguns minutos)...\n" 2>&1 | tee -a "$LOG"

~/.local/bin/mise install php@8.3 2>&1 | tee -a "$LOG"
~/.local/bin/mise use --global php@8.3 2>&1 | tee -a "$LOG"

printf "${OK} PHP 8.3 instalado e configurado como padrão\n" 2>&1 | tee -a "$LOG"

# Verificar instalação
PHP_VERSION=$(~/.local/bin/mise exec -- php -v | head -n 1)
printf "${NOTE} Versão do PHP: $PHP_VERSION\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 6. INSTALAR COMPOSER
# =============================================================================
printf "${NOTE} Instalando Composer...\n" 2>&1 | tee -a "$LOG"

cd /tmp
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" 2>&1 | tee -a "$LOG"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer 2>&1 | tee -a "$LOG"
php -r "unlink('composer-setup.php');" 2>&1 | tee -a "$LOG"
cd "$PARENT_DIR" > /dev/null

printf "${OK} Composer instalado\n" 2>&1 | tee -a "$LOG"

COMPOSER_VERSION=$(composer --version)
printf "${NOTE} $COMPOSER_VERSION\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 7. INSTALAR DOCKER
# =============================================================================
printf "${NOTE} Instalando Docker...\n" 2>&1 | tee -a "$LOG"

# Remover versões antigas
sudo dnf remove -y docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-selinux \
    docker-engine-selinux docker-engine 2>/dev/null || true

# Instalar dependências
sudo dnf install -y dnf-plugins-core 2>&1 | tee -a "$LOG"

# Adicionar repositório
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo 2>&1 | tee -a "$LOG"

# Instalar Docker
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>&1 | tee -a "$LOG"

# Iniciar e habilitar serviço
sudo systemctl start docker 2>&1 | tee -a "$LOG"
sudo systemctl enable docker 2>&1 | tee -a "$LOG"

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER 2>&1 | tee -a "$LOG"

printf "${OK} Docker instalado\n" 2>&1 | tee -a "$LOG"
printf "${WARN} IMPORTANTE: Faça logout/login ou reinicie para usar Docker sem sudo\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 8. INSTALAR MICROSOFT TEAMS (FLATPAK)
# =============================================================================
printf "${NOTE} Instalando Microsoft Teams...\n" 2>&1 | tee -a "$LOG"

flatpak install flathub com.github.IsmaelMartinez.teams_for_linux -y 2>&1 | tee -a "$LOG"

printf "${OK} Microsoft Teams instalado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 9. INSTALAR POSTMAN (FLATPAK)
# =============================================================================
printf "${NOTE} Instalando Postman...\n" 2>&1 | tee -a "$LOG"

flatpak install flathub com.getpostman.Postman -y 2>&1 | tee -a "$LOG"

printf "${OK} Postman instalado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# 10. INSTALAR FUSE (para AppImages)
# =============================================================================
printf "${NOTE} Instalando FUSE (suporte para AppImages)...\n" 2>&1 | tee -a "$LOG"

sudo dnf install -y fuse fuse-libs 2>&1 | tee -a "$LOG"

printf "${OK} FUSE instalado\n" 2>&1 | tee -a "$LOG"

# =============================================================================
# VERIFICAÇÕES FINAIS
# =============================================================================
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║          INSTALAÇÃO CONCLUÍDA COM SUCESSO! ✓             ║${RESET}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${RESET}"
echo ""

printf "${NOTE} Resumo das instalações:\n" 2>&1 | tee -a "$LOG"
echo ""

# VS Code
if command -v code &> /dev/null; then
    printf "${OK} VS Code: $(code --version | head -n 1)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} VS Code: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# Mise
if command -v mise &> /dev/null || [ -f "$HOME/.local/bin/mise" ]; then
    printf "${OK} Mise: $(~/.local/bin/mise --version)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} Mise: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# PHP
if ~/.local/bin/mise exec -- php -v &> /dev/null; then
    printf "${OK} PHP: $(~/.local/bin/mise exec -- php -v | head -n 1)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} PHP: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# Composer
if command -v composer &> /dev/null; then
    printf "${OK} Composer: $(composer --version | head -n 1)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} Composer: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# Docker
if command -v docker &> /dev/null; then
    printf "${OK} Docker: $(docker --version)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} Docker: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# Teams
if flatpak list | grep -q teams_for_linux; then
    printf "${OK} Microsoft Teams: Instalado (Flatpak)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} Microsoft Teams: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

# Postman
if flatpak list | grep -q Postman; then
    printf "${OK} Postman: Instalado (Flatpak)\n" 2>&1 | tee -a "$LOG"
else
    printf "${ERROR} Postman: NÃO ENCONTRADO\n" 2>&1 | tee -a "$LOG"
fi

echo ""
printf "${WARN} PRÓXIMOS PASSOS:\n" 2>&1 | tee -a "$LOG"
echo ""
echo "1. Reinicie o terminal ou execute: source $SHELL_RC"
echo "2. Para usar Docker sem sudo, faça LOGOUT e LOGIN novamente"
echo "3. Teste o PHP: php -v"
echo "4. Teste o Composer: composer --version"
echo "5. Teste o Docker: docker run hello-world"
echo ""
printf "${NOTE} Para instalar outras versões do PHP:\n" 2>&1 | tee -a "$LOG"
echo "   mise install php@8.2"
echo "   mise use php@8.2"
echo ""
printf "${NOTE} Para instalar Node.js, Python, Ruby, etc:\n" 2>&1 | tee -a "$LOG"
echo "   mise install node@20"
echo "   mise install python@3.12"
echo ""

printf "${OK} Configuração completa! Aproveite seu ambiente de desenvolvimento! 🚀\n" 2>&1 | tee -a "$LOG"

printf "\n%.0s" {1..2}
