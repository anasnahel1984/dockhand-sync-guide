# Konfigurasi Sinkronisasi Dockhand ↔ GitHub (Dua Arah)

Dokumen ini menjelaskan langkah-langkah untuk mengonfigurasi sinkronisasi dua arah antara Dockhand dan repositori GitHub. Sinkronisasi ini akan memungkinkan Dockhand untuk secara otomatis memperbarui *stack* Docker Compose berdasarkan perubahan di repositori GitHub, dan juga menyediakan mekanisme untuk menyinkronkan perubahan dari Dockhand kembali ke GitHub.

## 1. Sinkronisasi GitHub ke Dockhand

Dockhand mendukung integrasi Git untuk secara otomatis menyebarkan *stack* Docker Compose dari repositori GitHub. Ada dua metode utama untuk memicu sinkronisasi ini:

### 1.1. Menggunakan Webhook GitHub (Direkomendasikan untuk Sinkronisasi Real-time)

Webhook GitHub memungkinkan Dockhand untuk menerima pemberitahuan setiap kali ada perubahan (misalnya, *push* kode) di repositori Anda, dan kemudian memicu penyebaran ulang *stack* Docker Compose yang relevan.

**Langkah-langkah Konfigurasi:**

1.  **Di Dockhand:**
    *   Pastikan Dockhand Anda berjalan dan dapat diakses.
    *   Navigasikan ke bagian **Compose Stacks** dan buat atau edit *stack* yang ingin Anda sinkronkan dengan GitHub.
    *   Di pengaturan *stack*, cari opsi **Git Integration** dan hubungkan ke repositori GitHub Anda. Anda perlu memberikan kredensial GitHub (token akses pribadi) agar Dockhand dapat mengakses repositori.
    *   Setelah terhubung, Dockhand akan menghasilkan **Webhook URL** unik untuk *stack* tersebut. Salin URL ini.
    *   (Opsional) Konfigurasi **Webhook Secret** di Dockhand untuk keamanan tambahan. Ini akan digunakan untuk memverifikasi bahwa permintaan webhook berasal dari GitHub yang sah.

2.  **Di GitHub:**
    *   Buka repositori GitHub Anda di peramban web.
    *   Navigasikan ke **Settings** > **Webhooks**.
    *   Klik **Add webhook**.
    *   **Payload URL**: Tempelkan Webhook URL yang Anda salin dari Dockhand.
    *   **Content type**: Pilih `application/json`.
    *   **Secret**: Jika Anda mengonfigurasi Webhook Secret di Dockhand, masukkan nilai yang sama di sini.
    *   **Which events would you like to trigger this webhook?**: Pilih `Just the push event.` atau sesuaikan sesuai kebutuhan Anda.
    *   Pastikan **Active** dicentang.
    *   Klik **Add webhook**.

Sekarang, setiap kali Anda melakukan *push* ke repositori GitHub, GitHub akan mengirimkan pemberitahuan ke Dockhand, yang kemudian akan memicu penyebaran ulang *stack* Docker Compose Anda.

### 1.2. Menggunakan Auto-sync Terjadwal Dockhand (Opsional, sebagai Cadangan)

Anda juga dapat mengonfigurasi Dockhand untuk secara berkala memeriksa perubahan di repositori GitHub dan menyinkronkan *stack* secara otomatis.

**Langkah-langkah Konfigurasi:**

1.  **Di Dockhand:**
    *   Navigasikan ke pengaturan *stack* yang relevan.
    *   Di bagian **Git Integration**, aktifkan opsi **Auto-sync**.
    *   Tentukan ekspresi Cron untuk jadwal sinkronisasi. Misalnya, `0 */15 * * * *` akan menyinkronkan setiap 15 menit.

## 2. Sinkronisasi Dockhand ke GitHub (Solusi yang Diusulkan)

Dockhand tidak memiliki fitur bawaan untuk secara otomatis mendorong perubahan konfigurasi yang dibuat melalui UI-nya kembali ke repositori Git. Namun, Dockhand menyimpan semua data dan konfigurasinya di direktori lokal (biasanya `/opt/dockhand` atau volume Docker yang terpasang).

Untuk mencapai sinkronisasi dua arah, kita dapat menerapkan solusi kustom yang memantau direktori data Dockhand dan mendorong perubahan ke repositori GitHub.

**Solusi yang Diusulkan:**

1.  **Identifikasi Direktori Data Dockhand:**
    *   Temukan lokasi volume Docker atau direktori di mana Dockhand menyimpan data konfigurasinya. Ini biasanya dikonfigurasi saat Anda menjalankan Dockhand (misalnya, melalui *bind mount* di `docker-compose.yml`).

2.  **Buat Repositori GitHub Khusus:**
    *   Buat repositori GitHub baru (misalnya, `dockhand-configs`) yang akan berfungsi sebagai tujuan untuk konfigurasi Dockhand Anda.

3.  **Gunakan Skrip Sinkronisasi (misalnya, `git-sync` atau Skrip Kustom):**
    *   Anda dapat menggunakan alat seperti `git-sync` (sebuah *sidecar container* yang dirancang untuk menyinkronkan direktori lokal dengan repositori Git) atau membuat skrip Bash kustom yang berjalan sebagai *cron job* di *host* atau sebagai *container* terpisah.

    **Contoh Skrip Bash Sederhana (untuk dijalankan sebagai Cron Job di Host):**

    ```bash
    #!/bash/bash

    DOCKHAND_CONFIG_DIR="/path/to/your/dockhand/data"
    GIT_REPO_DIR="/path/to/local/git/repo"
    GITHUB_REPO_URL="https://github.com/your-username/dockhand-configs.git"
    GIT_BRANCH="main"

    cd "$GIT_REPO_DIR"

    # Pastikan repositori sudah di-clone
    if [ ! -d ".git" ]; then
      git clone "$GITHUB_REPO_URL" .
      git checkout "$GIT_BRANCH"
    fi

    # Salin konfigurasi Dockhand ke repositori lokal
    rsync -av --delete "$DOCKHAND_CONFIG_DIR/" "$GIT_REPO_DIR/"

    # Tambahkan semua perubahan, commit, dan push
    git add .
    git commit -m "Sync Dockhand configurations from $(hostname) - $(date)" || true
    git push origin "$GIT_BRANCH"
    ```

    **Catatan:**
    *   Ganti `/path/to/your/dockhand/data` dengan direktori data Dockhand Anda yang sebenarnya.
    *   Ganti `/path/to/local/git/repo` dengan direktori lokal tempat Anda akan mengkloning repositori GitHub `dockhand-configs`.
    *   Ganti `https://github.com/your-username/dockhand-configs.git` dengan URL repositori GitHub Anda.
    *   Pastikan kredensial Git (misalnya, token akses pribadi GitHub) dikonfigurasi dengan benar di lingkungan tempat skrip ini berjalan, atau gunakan SSH *key*.
    *   `|| true` ditambahkan ke perintah `git commit` untuk mencegah skrip gagal jika tidak ada perubahan untuk di-commit.

4.  **Jadwalkan Skrip:**
    *   Jalankan skrip ini secara berkala menggunakan `cron` di sistem *host* Anda. Misalnya, untuk menjalankannya setiap 5 menit:

        ```bash
        crontab -e
        ```

        Tambahkan baris berikut:

        ```
        */5 * * * * /path/to/your/sync_script.sh
        ```

## 3. Sinkronisasi Otomatis dari `/opt/dockhand/repo` ke GitHub

Jika Anda ingin menyinkronkan file spesifik dari direktori `/opt/dockhand/repo` (tempat Dockhand menyimpan repositori lokal) ke GitHub, Anda dapat menggunakan skrip otomatisasi yang disediakan.

### 3.1. Persiapan Skrip

1.  **Unduh Skrip**: Gunakan skrip `sync_dockhand.sh` yang tersedia di repositori ini.
2.  **Berikan Izin Eksekusi**:
    ```bash
    chmod +x sync_dockhand.sh
    ```
3.  **Sesuaikan Konfigurasi**: Buka skrip dan pastikan `GITHUB_REPO_URL` mengarah ke repositori tujuan Anda (misalnya repositori `app`).

### 3.2. Menjalankan sebagai Layanan (Systemd)

Agar sinkronisasi berjalan terus-menerus di latar belakang, Anda bisa menginstalnya sebagai layanan systemd:

1.  Salin file layanan:
    ```bash
    sudo cp dockhand-sync.service /etc/systemd/system/
    ```
2.  Muat ulang daemon dan aktifkan layanan:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable dockhand-sync.service
    sudo systemctl start dockhand-sync.service
    ```

Layanan ini akan menjalankan skrip sinkronisasi setiap 5 menit (300 detik) secara otomatis.

### 3.3. Alternatif: Menggunakan Cron

Jika Anda lebih suka menggunakan Cron, tambahkan baris berikut ke crontab Anda (`crontab -e`):

```bash
*/5 * * * * /bin/bash /home/ubuntu/dockhand-sync-guide/sync_dockhand.sh >> /home/ubuntu/sync.log 2>&1
```

## Referensi

*   [Dockhand User Manual - Git Integration](https://dockhand.pro/manual/#stacks-git)
*   [Dockhand User Manual - Webhooks](https://dockhand.pro/manual/#stacks-webhooks)
*   [Dockhand User Manual - API Reference](https://dockhand.pro/manual/#api-reference)
