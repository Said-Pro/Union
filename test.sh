#!/bin/bash
# Script d'installation pour UnionStream (version avec kill uniquement)
# Les commandes originales sont conservées intégralement.

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Vérifier que le script est exécuté en root
if [[ $EUID -ne 0 ]]; then
    error "Ce script doit être exécuté en tant que root (utilisez sudo ou connectez-vous en root)."
    exit 1
fi

# Vérifier la présence des commandes nécessaires
MISSING=""
for cmd in wget tar killall; do
    if ! command -v $cmd &> /dev/null; then
        MISSING="$MISSING $cmd"
    fi
done
if [[ -n "$MISSING" ]]; then
    error "Commandes manquantes :$MISSING. Installez-les avant de continuer."
    exit 1
fi

# Vérifier que le répertoire de destination existe
DEST_DIR="/usr/lib/enigma2/python/Plugins/Extensions"
if [[ ! -d "$DEST_DIR" ]]; then
    warn "Le répertoire $DEST_DIR n'existe pas."
    read -p "Voulez-vous le créer ? (o/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        mkdir -p "$DEST_DIR"
        if [[ $? -ne 0 ]]; then
            error "Impossible de créer le répertoire. Vérifiez les permissions."
            exit 1
        fi
        success "Répertoire créé."
    else
        error "Installation annulée."
        exit 1
    fi
fi

# Vérifier l'espace disque dans /tmp (au moins 10 Mo)
TMP_AVAIL=$(df /tmp | awk 'NR==2 {print $4}')
if [[ $TMP_AVAIL -lt 10240 ]]; then
    error "Espace insuffisant dans /tmp (moins de 10 Mo). Libérez de l'espace."
    exit 1
fi

# Vérifier l'espace disque dans la destination (au moins 10 Mo)
DEST_AVAIL=$(df "$DEST_DIR" | awk 'NR==2 {print $4}')
if [[ $DEST_AVAIL -lt 10240 ]]; then
    error "Espace insuffisant dans $DEST_DIR (moins de 10 Mo)."
    exit 1
fi

# Demander confirmation globale
echo
info "Ce script va installer le plugin UnionStream sur votre récepteur."
info "Source : https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz"
info "Destination : $DEST_DIR"
warn "Attention : après l'installation, Enigma2 sera tué (kill -9) mais pas redémarré automatiquement."
warn "Vous devrez redémarrer Enigma2 manuellement (par exemple avec 'systemctl restart enigma2' ou en rebooting)."
read -p "Voulez-vous continuer ? (o/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Oo]$ ]]; then
    info "Installation annulée."
    exit 0
fi

# Étape 1 : Téléchargement
info "Téléchargement de l'archive..."
wget -O /tmp/UnionStream.tar.gz https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz
if [[ $? -ne 0 || ! -f /tmp/UnionStream.tar.gz ]]; then
    error "Échec du téléchargement."
    exit 1
fi
success "Téléchargement terminé."

# Étape 2 : Extraction
info "Extraction de l'archive vers $DEST_DIR..."
cd /tmp/
tar -xzf UnionStream.tar.gz -C "$DEST_DIR"
if [[ $? -ne 0 ]]; then
    error "Échec de l'extraction."
    rm -f /tmp/UnionStream.tar.gz
    exit 1
fi
success "Extraction terminée."

# Optionnel : lister les fichiers installés
info "Fichiers installés :"
ls -la "$DEST_DIR" | grep -E "Union|Stream" 2>/dev/null || echo "Aucun fichier visible (peut-être un nom différent)."

# Étape 3 : Nettoyage
info "Nettoyage de l'archive temporaire..."
rm -f /tmp/UnionStream.tar.gz
success "Nettoyage effectué."

# Étape 4 : Arrêt d'Enigma2
warn "La commande 'killall -9 enigma2' va maintenant être exécutée."
warn "Enigma2 sera arrêté immédiatement. Le récepteur perdra son interface."
warn "Pour le redémarrer, vous devrez :"
warn "  - Soit exécuter 'systemctl restart enigma2' (si systemd est utilisé)"
warn "  - Soit redémarrer physiquement le récepteur"
read -p "Confirmer l'arrêt d'Enigma2 ? (o/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Oo]$ ]]; then
    info "Arrêt forcé d'Enigma2..."
    killall -9 enigma2
    if [[ $? -eq 0 ]]; then
        success "Commande kill exécutée. Enigma2 a été arrêté."
    else
        warn "La commande killall a échoué (peut-être qu'Enigma2 n'était pas en cours d'exécution ?)."
    fi
else
    warn "Arrêt annulé. Enigma2 n'a pas été tué."
fi

# Message final
echo
success "Installation terminée."
info "Rappel : Enigma2 n'est pas redémarré automatiquement."
info "Pour utiliser le plugin, redémarrez Enigma2 manuellement ou rebooting."
