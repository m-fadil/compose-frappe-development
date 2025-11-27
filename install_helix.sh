#!/usr/bin/env bash
set -euo pipefail

# Konfigurasi URL & path
HX_URL="https://github.com/m-fadil/compose-frappe-development/releases/download/v1.0.0/hx"
HELIX_TARBALL_URL="https://github.com/helix-editor/helix/releases/download/25.07.1/helix-25.07.1-x86_64-linux.tar.xz"
HELIX_TARBALL="helix-25.07.1-x86_64-linux.tar.xz"
HELIX_SHARE_DIR="/usr/local/share/helix"
HELIX_RUNTIME_DIR="$HELIX_SHARE_DIR/runtime"

echo "Pindah ke home directory..."
cd "$HOME"

echo "Mengunduh hx..."
curl -L -o hx "$HX_URL"

echo "Mengatur permission executable untuk hx..."
chmod +x hx

echo "Memindahkan hx ke /usr/local/bin (memerlukan sudo)..."
sudo mv hx /usr/local/bin/hx

echo "Mengunduh Helix tarball..."
curl -L -o "$HELIX_TARBALL" "$HELIX_TARBALL_URL"

echo "Mengekstrak Helix..."
tar xf "$HELIX_TARBALL"

# Cari folder runtime hasil extract
echo "Mencari folder runtime..."
if [ -d "helix-25.07.1-x86_64-linux/runtime" ]; then
  RUNTIME_SRC="helix-25.07.1-x86_64-linux/runtime"
elif [ -d "runtime" ]; then
  RUNTIME_SRC="runtime"
else
  echo "Error: Folder 'runtime' tidak ditemukan setelah ekstraksi."
  exit 1
fi

echo "Menyiapkan direktori /usr/local/share/helix..."
sudo mkdir -p "$HELIX_SHARE_DIR"

echo "Memindahkan runtime ke $HELIX_RUNTIME_DIR..."
# Hapus direktori runtime lama jika ada
sudo rm -rf "$HELIX_RUNTIME_DIR"
sudo mv "$RUNTIME_SRC" "$HELIX_RUNTIME_DIR"

echo "Menyiapkan direktori ~/.config/helix..."
mkdir -p "$HOME/.config/helix"

echo "Membuat symlink runtime ke ~/.config/helix/runtime..."
# Hapus symlink atau direktori lama jika ada
if [ -L "$HOME/.config/helix/runtime" ] || [ -d "$HOME/.config/helix/runtime" ]; then
  rm -rf "$HOME/.config/helix/runtime"
fi
ln -s "$HELIX_RUNTIME_DIR" "$HOME/.config/helix/runtime"

echo "Membersihkan file tarball..."
rm -f "$HELIX_TARBALL"

# Hapus folder ekstraksi jika masih ada
if [ -d "helix-25.07.1-x86_64-linux" ]; then
  rm -rf "helix-25.07.1-x86_64-linux"
fi

echo "Instalasi selesai. hx dan Helix runtime telah terpasang."
echo "Verifikasi instalasi dengan menjalankan: hx --version"
