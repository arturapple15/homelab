#!/bin/bash

# Останавливать скрипт при ошибках
set -e

echo "=== Запуск установки Samba ==="

# 1. Обновление и установка пакетов
echo "Установка пакетов..."
sudo apt update && sudo apt install samba cifs-utils -y

# 2. Создание пользователя (если не существует)
if ! id "smbuser" &>/dev/null; then
    echo "Создание пользователя smbuser..."
    sudo adduser --disabled-password --gecos "" smbuser
else
    echo "Пользователь smbuser уже существует."
fi

# 3. Установка пароля Samba
echo "Установите сетевой пароль для smbuser:"
sudo smbpasswd -a smbuser

# 4. Создание папки и настройка прав
echo "Настройка директории /srv/samba/share..."
sudo mkdir -p /srv/samba/share
sudo chown -R smbuser:smbuser /srv/samba/share
sudo chmod -R 2770 /srv/samba/share

# 5. Копирование конфигурации
echo "Применение конфигурации Samba..."
if [ -f "/etc/samba/smb.conf" ]; then
    sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
fi
sudo cp smb.conf.template /etc/samba/smb.conf

# 6. Перезапуск служб
echo "Запуск служб..."
sudo systemctl restart smbd nmbd
sudo systemctl enable --now smbd nmbd

# 7. Настройка брандмауэра UFW
if sudo ufw status | grep -q "Status: active"; then
    echo "Настройка UFW..."
    sudo ufw allow samba
    sudo ufw reload
fi

echo "=== Установка успешно завершена! ==="
echo "Шара доступна по адресу: \\\\<IP_СЕРВЕРА>\\Share"
