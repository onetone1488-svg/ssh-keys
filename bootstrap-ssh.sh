#!/usr/bin/env bash
set -euo pipefail

PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFLfg1qSk4QiHkfOd0iHV+I+ztBwln/79d6w2iMki7+5 oneto-rodina-2026"
SSH_USER="${SUDO_USER:-$USER}"
SSH_DIR="/root/.ssh"   # или /home/$SSH_USER/.ssh если не под root

# 1. Кладём ключ
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$SSH_DIR/authorized_keys"
grep -qxF "$PUBKEY" "$SSH_DIR/authorized_keys" || echo "$PUBKEY" >> "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/authorized_keys"

# 2. Правим sshd_config — атомарно и с бэкапом
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"

sed -i \
  -e 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' \
  -e 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' \
  -e 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' \
  "$SSHD_CONFIG"

# на некоторых системах (Ubuntu 22+) есть override в /etc/ssh/sshd_config.d/
if [ -d /etc/ssh/sshd_config.d ]; then
  echo -e "PasswordAuthentication no\nPubkeyAuthentication yes" > /etc/ssh/sshd_config.d/99-hardening.conf
fi

# 3. Проверка конфига ПЕРЕД рестартом — критично!
sshd -t || { echo "sshd config broken, rollback"; cp "${SSHD_CONFIG}.bak."* "$SSHD_CONFIG"; exit 1; }

systemctl restart sshd || systemctl restart ssh

echo "✅ Key added, password auth disabled. Test new connection in another terminal BEFORE closing this session!"
