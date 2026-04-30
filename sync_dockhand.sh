#!/bin/bash

# Konfigurasi
SOURCE_DIR="/opt/dockhand/repo"
GIT_REPO_DIR="/home/ubuntu/dockhand-app-sync" # Direktori lokal untuk git
GITHUB_REPO_URL="https://github.com/anasnahel1984/app.git" # Ganti dengan nama repo yang sesuai
BRANCH="main"

# Pastikan direktori git sudah ada dan terinisialisasi
if [ ! -d "$GIT_REPO_DIR/.git" ]; then
    echo "Inisialisasi repositori git lokal..."
    mkdir -p "$GIT_REPO_DIR"
    cd "$GIT_REPO_DIR"
    git clone "$GITHUB_REPO_URL" .
fi

cd "$GIT_REPO_DIR"

# Sinkronisasi file dari /opt/dockhand/repo ke direktori git
# Menggunakan rsync untuk efisiensi, mengabaikan folder .git di sumber jika ada
echo "Menyinkronkan file dari $SOURCE_DIR..."
rsync -av --delete --exclude '.git' "$SOURCE_DIR/" "$GIT_REPO_DIR/"

# Cek apakah ada perubahan
if [[ -n $(git status -s) ]]; then
    echo "Perubahan terdeteksi, melakukan push ke GitHub..."
    git add .
    git commit -m "Auto-sync dari Dockhand: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin "$BRANCH"
    echo "Sinkronisasi selesai."
else
    echo "Tidak ada perubahan yang terdeteksi."
fi
