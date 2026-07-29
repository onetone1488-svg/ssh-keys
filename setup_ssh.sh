#!/bin/bash

# Ваш публичный SSH-ключ
PUB_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFLfg1qSk4QiHkfOd0iHV+I+ztBwln/79d6w2iMki7+5 oneto-rodina-2026"

echo "Начинаем настройку SSH..."

# 1. Создаем папку .ssh и устанавливаем правильные права
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 2. Добавляем ключ в authorized_keys (если его там еще нет)
if ! grep -q "$PUB_KEY" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "$PUB_KEY" >> ~/.ssh/authorized_keys
fi
chmod 600 ~/.ssh/authorized_keys

# 3. Проверяем, что ключ успешно добавлен
if grep -q "$PUB_KEY" ~/.ssh/authorized_keys; then
    echo "✅ SSH-ключ успешно добавлен и проверен."
    
    # Проверяем, есть ли права root/sudo для изменения конфигурации sshd
    if [ "$EUID" -ne 0 ]; then
        # Пытаемся использовать sudo
        SUDO="sudo"
    else
        SUDO=""
    fi
    
    echo "Отключаем вход по паролю..."
    
    # 4. Включаем вход по ключу и отключаем по паролю в sshd_config
    $SUDO sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    $SUDO sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    
    # 5. Перезапускаем службу SSH
    if $SUDO systemctl is-active --quiet sshd; then
        $SUDO systemctl restart sshd
        echo "✅ Служба sshd перезапущена."
    elif $SUDO systemctl is-active --quiet ssh; then
        $SUDO systemctl restart ssh
        echo "✅ Служба ssh перезапущена."
    else
        echo "⚠️ Не удалось автоматически перезапустить SSH-сервер. Пожалуйста, сделайте это вручную (systemctl restart sshd)."
    fi
    
    echo "🎉 Готово! Теперь вы можете входить только по SSH-ключу."
else
    echo "❌ Ошибка: Не удалось добавить SSH-ключ. Отключение паролей прервано, чтобы вы не потеряли доступ."
    exit 1
fi