#!/bin/bash

# ============================================================
#  Installateur de plugin Enigma2 - UnionStream
#  Compatible : Dreambox, Vu+, Gigablue, Formuler, etc.
# ============================================================

# --- Configuration ---
PLUGIN_URL="https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz"
PLUGIN_NAME="UnionStream"
TMP_FILE="/tmp/${PLUGIN_NAME}.tar.gz"
PLUGIN_DIR="/usr/lib/enigma2/python/Plugins/Extensions"

# --- Couleurs pour les messages ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERREUR]${NC} $1"; exit 1; }

# -------------------------------------------------------
# 1. Vérification des droits root
# -------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    log_error "Ce script doit être exécuté en tant que root (sudo ./install.sh)"
fi

# -------------------------------------------------------
# 2. Vérification que le répertoire des plugins existe
# -------------------------------------------------------
if [ ! -d "$PLUGIN_DIR" ]; then
    log_error "Répertoire des plugins introuvable : $PLUGIN_DIR\nVérifiez que Enigma2 est bien installé sur ce système."
fi

# -------------------------------------------------------
# 3. Téléchargement
# -------------------------------------------------------
log_info "Téléchargement de ${PLUGIN_NAME}..."
wget --timeout=30 --tries=3 -q --show-progress -O "$TMP_FILE" "$PLUGIN_URL"

if [ $? -ne 0 ] || [ ! -f "$TMP_FILE" ]; then
    rm -f "$TMP_FILE"
    log_error "Échec du téléchargement. Vérifiez votre connexion internet."
fi
log_info "Téléchargement terminé."

# -------------------------------------------------------
# 4. Vérification de l'archive
# -------------------------------------------------------
log_info "Vérification de l'archive..."
if ! tar -tzf "$TMP_FILE" > /dev/null 2>&1; then
    rm -f "$TMP_FILE"
    log_error "L'archive est corrompue ou invalide."
fi

# -------------------------------------------------------
# 5. Suppression de l'ancienne version (si présente)
# -------------------------------------------------------
if [ -d "${PLUGIN_DIR}/${PLUGIN_NAME}" ]; then
    log_warn "Ancienne version détectée — suppression en cours..."
    rm -rf "${PLUGIN_DIR:?}/${PLUGIN_NAME}"
fi

# -------------------------------------------------------
# 6. Installation
# -------------------------------------------------------
log_info "Installation dans ${PLUGIN_DIR}..."
tar -xzf "$TMP_FILE" -C "$PLUGIN_DIR"

if [ $? -ne 0 ]; then
    rm -f "$TMP_FILE"
    log_error "Échec de l'extraction. Vérifiez les permissions du répertoire."
fi

# -------------------------------------------------------
# 7. Nettoyage
# -------------------------------------------------------
rm -f "$TMP_FILE"
log_info "Fichiers temporaires supprimés."

# -------------------------------------------------------
# 8. Redémarrage propre d'Enigma2
# -------------------------------------------------------
log_info "Redémarrage d'Enigma2..."

if command -v systemctl &> /dev/null; then
    systemctl restart enigma2
elif command -v init &> /dev/null; then
    # Fallback pour les récepteurs sans systemd (ex: Dreambox OpenDreamux)
    kill -HUP $(pidof enigma2) 2>/dev/null || killall enigma2 2>/dev/null
else
    log_warn "Impossible de redémarrer Enigma2 automatiquement."
    log_warn "Redémarrez votre récepteur manuellement."
fi

echo ""
log_info "✅ Plugin '${PLUGIN_NAME}' installé avec succès !"
echo -e "   → Accès : Menu > Plugins > ${PLUGIN_NAME}"
echo ""
