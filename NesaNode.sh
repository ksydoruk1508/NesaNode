#!/bin/bash

# Цвета текста
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # Нет цвета (сброс цвета)

# Проверка наличия curl и установка, если не установлен
if ! command -v curl &> /dev/null; then
    sudo apt update
    sudo apt install curl -y
fi
sleep 1

echo -e "${GREEN}"
cat << "EOF"
███    ██ ███████ ███████  █████      ███    ██  ██████  ██████  ███████ 
████   ██ ██      ██      ██   ██     ████   ██ ██    ██ ██   ██ ██      
██ ██  ██ █████   ███████ ███████     ██ ██  ██ ██    ██ ██   ██ █████   
██  ██ ██ ██           ██ ██   ██     ██  ██ ██ ██    ██ ██   ██ ██      
██   ████ ███████ ███████ ██   ██     ██   ████  ██████  ██████  ███████

________________________________________________________________________________________________________________________________________


███████  ██████  ██████      ██   ██ ███████ ███████ ██████      ██ ████████     ████████ ██████   █████  ██████  ██ ███    ██  ██████  
██      ██    ██ ██   ██     ██  ██  ██      ██      ██   ██     ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ████   ██ ██       
█████   ██    ██ ██████      █████   █████   █████   ██████      ██    ██           ██    ██████  ███████ ██   ██ ██ ██ ██  ██ ██   ███ 
██      ██    ██ ██   ██     ██  ██  ██      ██      ██          ██    ██           ██    ██   ██ ██   ██ ██   ██ ██ ██  ██ ██ ██    ██ 
██       ██████  ██   ██     ██   ██ ███████ ███████ ██          ██    ██           ██    ██   ██ ██   ██ ██████  ██ ██   ████  ██████  
                                                                                                                                         
                                                                                                                                         
 ██  ██████  ██       █████  ███    ██ ██████   █████  ███    ██ ████████ ███████                                                         
██  ██        ██     ██   ██ ████   ██ ██   ██ ██   ██ ████   ██    ██    ██                                                             
██  ██        ██     ███████ ██ ██  ██ ██   ██ ███████ ██ ██  ██    ██    █████                                                          
██  ██        ██     ██   ██ ██  ██ ██ ██   ██ ██   ██ ██  ██ ██    ██    ██                                                             
 ██  ██████  ██      ██   ██ ██   ████ ██████  ██   ██ ██   ████    ██    ███████

Donate: 0x0004230c13c3890F34Bb9C9683b91f539E809000
EOF
echo -e "${NC}"

function install_node {
    echo -e "${BLUE}Обновляем сервер...${NC}"
    sudo apt-get update -y && sudo apt upgrade -y && sudo apt install -y jq

    echo -e "${BLUE}Устанавливаем Docker...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    echo -e "${BLUE}Устанавливаем Docker Compose...${NC}"
    VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    curl -L "https://github.com/docker/compose/releases/download/"$VER"/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version

    echo -e "${BLUE}Открываем порт...${NC}"
    sudo ufw allow 31333

    echo -e "${BLUE}Запускаем установочный скрипт...${NC}"
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

    echo -e "${GREEN}Нода Nesa успешно установлена!${NC}"
}

function restart_node {
    echo -e "${BLUE}Перезапускаем Docker контейнеры...${NC}"
    docker restart orchestrator ipfs_node mongodb docker-watchtower-1
}

function view_logs {
    echo -e "${YELLOW}Просмотр логов orchestrator (выход из логов CTRL+C)...${NC}"
    docker logs -f orchestrator --tail=50
}

function view_node_id {
    echo -e "${BLUE}Ваш Node ID:${NC}"
    cat $HOME/.nesa/identity/node_id.id
}

function enable_auto_restart {
    echo -e "${BLUE}Устанавливаем crontab для автоматического перезапуска...${NC}"
    sudo apt install -y cron
    (crontab -l 2>/dev/null; echo "# Docker restart of orchestrator container to make NESA run properly") | crontab -
    (crontab -l 2>/dev/null; echo "0 */2 * * * docker restart orchestrator ipfs_node mongodb docker-watchtower-1") | crontab -
    echo -e "${GREEN}Автоматический перезапуск каждые 2 часа успешно настроен.${NC}"
}

function change_port {
    echo -e "${YELLOW}Изменение порта...${NC}"
    echo -e "${YELLOW}Редактируйте файл конфигурации вручную: nano ~/.nesa/docker/compose.ipfs.yml${NC}"
    echo -e "${YELLOW}После изменения перезапустите ноду командой 'bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)'${NC}"
}

function remove_node {
    echo -e "${BLUE}Удаляем Docker контейнеры и директорию...${NC}"
    docker stop orchestrator ipfs_node mongodb docker-watchtower-1 && docker rm orchestrator ipfs_node mongodb docker-watchtower-1 --force 2>/dev/null || echo -e "${RED}Контейнеры не найдены.${NC}"
    if [ -d "$HOME/.nesa" ]; then
        rm -rf $HOME/.nesa
        echo -e "${GREEN}Нода успешно удалена.${NC}"
    else
        echo -e "${RED}Директория ~/.nesa не найдена.${NC}"
    fi
}

function main_menu {
    while true; do
        echo -e "${YELLOW}Выберите действие:${NC}"
        echo -e "${CYAN}1. Установка ноды${NC}"
        echo -e "${CYAN}2. Рестарт ноды${NC}"
        echo -e "${CYAN}3. Просмотр логов${NC}"
        echo -e "${CYAN}4. Посмотреть Node ID${NC}"
        echo -e "${CYAN}5. Включить автоматический перезапуск каждые 2 часа${NC}"
        echo -e "${CYAN}6. Изменить порт${NC}"
        echo -e "${CYAN}7. Удаление ноды${NC}"
        echo -e "${CYAN}8. Выход${NC}"
       
        echo -e "${YELLOW}Введите номер:${NC} "
        read choice
        case $choice in
            1) install_node ;;
            2) restart_node ;;
            3) view_logs ;;
            4) view_node_id ;;
            5) enable_auto_restart ;;
            6) change_port ;;
            7) remove_node ;;
            8) break ;;
            *) echo -e "${RED}Неверный выбор, попробуйте снова.${NC}" ;;
        esac
    done
}

main_menu
