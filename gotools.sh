#!/bin/bash

set -e

#Definindo variaveis usadas na instalaçao
GO_VERSION=$(curl -s https://go.dev/dl/?mode=json | grep -oP '"version":\s*"\Kgo[0-9.]+' | head -n 1)
GO_DOWNLOAD_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
GO_INSTALL_DIR="/usr/local"
PROFILE_PATH="/etc/profile.d/golang.sh"
GOBIN="/usr/local/bin"


#Cores usadas no programa
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

#Array de ferramentas usadas para instalar/desinstalar ferramentas
TOOLS=(
    "github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    "github.com/projectdiscovery/httpx/cmd/httpx"
    "github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    "github.com/projectdiscovery/naabu/v2/cmd/naabu"
    "github.com/projectdiscovery/dnsx/cmd/dnsx"
    "github.com/projectdiscovery/katana/cmd/katana"
    "github.com/lc/gau/v2/cmd/gau"
    "github.com/tomnomnom/assetfinder"
    "github.com/tomnomnom/waybackurls"
    "github.com/tomnomnom/qsreplace"
    "github.com/tomnomnom/gf"
    "github.com/tomnomnom/anew"
    "github.com/ffuf/ffuf"
  )


# Caminhas para procurar por binarios
BIN_DIRS=(
  /usr/local/bin
  /usr/bin
  /bin
  /sbin
  /usr/sbin
  ~/.local/bin
  ~/go/bin
)


instalar_ferramentas(){
  echo -e "🔍 ${YELLOW}Checando instalaçao do GO...${RESET}"
  if ! command -v go &> /dev/null; then
      echo -e "⬇️ ${GREEN}Instalando GO ${GO_VERSION} do site oficial...${RESET}"
      wget -q $GO_DOWNLOAD_URL -O /tmp/go.tar.gz
      sudo rm -rf $GO_INSTALL_DIR/go
      sudo tar -C $GO_INSTALL_DIR -xzf /tmp/go.tar.gz
      echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee $PROFILE_PATH > /dev/null
      export PATH=$PATH:/usr/local/go/bin
  else
      INSTALLED_VERSION=$(go version | awk '{print $3}')
      if [[ "$INSTALLED_VERSION" != "go${GO_VERSION}" ]]; then
          echo -e "🔄 ${GREEN}Atualizando o GO para ${GO_VERSION}...${RESET}"
          wget -q $GO_DOWNLOAD_URL -O /tmp/go.tar.gz
          sudo rm -rf $GO_INSTALL_DIR/go
          sudo tar -C $GO_INSTALL_DIR -xzf /tmp/go.tar.gz
          export PATH=$PATH:/usr/local/go/bin
      else
          echo -e "✅ ${GREEN}GO já esta na versão mais atual (${GO_VERSION}).${RESET}"
      fi
  fi

  echo -e "📦 ${GREEN}Instalando dependencias...${RESET}"

  sudo apt install build-essential -y
  sudo apt install libpcap-dev -y

  echo -e "📦 ${GREEN}Instalando ferramentas...${RESET}"

  for TOOL in "${TOOLS[@]}"; do
      echo -e "🔧 ${GREEN}Instalando/Atualizando $(basename "$TOOL")...${RESET}"
      GOBIN=$GOBIN go install "$TOOL@latest"
  done

  echo -e "✅ ${GREEN}Todas as ferramentas foram instaladas em $GOBIN${RESET}"
}

desinstalar_ferramentas(){
  echo -e "${RED}Isso irá remover o GO e todas as ferramentas instaladas.${RESET}"
  echo -e "${RED}Você quer continuar? [y/N]: ${RESET}"
  read confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo -e "❌ ${YELLOW}Desinstalação cancelada.${RESET}"
      exit 1
  fi


  echo -e "🔍 ${YELLOW}Procurando ferramentas a serem desinstaladas.${RESET}"
  for tool in "${TOOLS[@]}"; do
    tool_name=$(basename "$tool")  # <-- extrai só o executável
    FOUND=0
    for dir in "${BIN_DIRS[@]}"; do
      if [[ -f "$dir/$tool_name" ]]; then
        echo -e "${YELLOW}Desinstalando $tool_name de $dir ${RESET}"
        sudo rm -f "$dir/$tool_name"
        FOUND=1
      fi
    done
    if [[ $FOUND -eq 0 ]]; then
      echo -e "ℹ️ ${YELLOW} $tool_name nao encontrada nos paths padrao ${RESET}"
    fi
  done


  # Remove Go de /usr/local/go
  if [[ -d "/usr/local/go" ]]; then
    echo -e "${YELLOW}Removendo GO de /usr/local/go${RESET}"
    sudo rm -rf /usr/local/go
  else
    echo -e "ℹ️ ${RED}GO nao encontrado em /usr/local/go${RESET}"
  fi

  # Remove Go path de ~/.profile or ~/.bashrc
  if grep -q "export PATH=\$PATH:/usr/local/go/bin" ~/.profile; then
    sed -i '/export PATH=\$PATH:\/usr\/local\/go\/bin/d' ~/.profile
    echo -e "🧹${GREEN} GO removido de ~/.profile${RESET}"
  fi
  if grep -q "export PATH=\$PATH:/usr/local/go/bin" ~/.bashrc; then
    sed -i '/export PATH=\$PATH:\/usr\/local\/go\/bin/d' ~/.bashrc
    echo -e "🧹${GREEN} GO removido de ~/.bashrc${RESET}"
  fi

  echo -e "${YELLOW}Voce quer deletar seu workspace e cache do GO (~/go and ~/.cache/go-build)? [y/N]: ${RESET}"
  read clean_cache
  if [[ "$clean_cache" == "y" || "$clean_cache" == "Y" ]]; then
    rm -rf ~/go ~/.cache/go-build
    echo -e "🧽${GREEN} Removidos ~/go e ~/.cache/go-build${RESET}"
  fi

  echo -e "✅ ${GREEN}Desinstalaçao completa.${RESET}"
}

echo -e "${GREEN}Digite i para instalar ou d para desisntalar as ferramentas: ${RESET}"
read escolha

if [[ "$escolha" == "i" || "$escolha" == "I" ]]; then
  instalar_ferramentas
elif [[ "$escolha" == "d" || "$escolha" == "D" ]]; then
  desinstalar_ferramentas
else
  echo -e "❌ ${RED}Escolha invalida. Tente novamente.${RESET}"
  exit 1
fi

