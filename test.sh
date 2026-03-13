#!/bin/sh
# Script d'installation pour UnionStream
# Détection de l'exécution via pipe et recommandation d'installation locale

# Couleurs (si supportées)
info() { printf "\033[0;34m[INFO]\033[0m %s\n" "$1"; }
error() { printf "\033[0;31m[ERROR]\033[0m %s\n" "$1"; }

# Vérifier si l'entrée standard est un terminal
if [ ! -t 0 ]; then
    echo
    error "Ce script nécessite une interaction utilisateur (clavier)."
    error "Il ne peut pas être exécuté directement via un pipe (wget | sh)."
    echo
    info "Veuillez suivre ces étapes :"
    info "1. Téléchargez le script localement :"
    info "   wget -q https://raw.githubusercontent.com/Said-Pro/Union/refs/heads/main/test.sh -O /tmp/test.sh"
    info "2. Rendez-le exécutable :"
    info "   chmod +x /tmp/test.sh"
    info "3. Exécutez-le :"
    info "   /tmp/test.sh"
    echo
    exit 1
fi

# ----------------------------------------------------------------------
# À partir d'ici, le script est en mode interactif (terminal)
# Toutes les commandes originales sont conservées inchangées.
# ----------------------------------------------------------------------

# Fonctions d'affichage
success() { printf "\033[0;32m[SUCCESS]\033[0m %s\n" "$1"; }
warn() { printf "\033[0;33m[WARN]\033[0m %s\n" "$1"; }

# Vérifier root
if [ "$(id -u)" -ne 0 ]; then
    error "Ce script doit être exécuté en tant que root."
    exit 1
fi

# Vérifier les commandes nécessaires
for cmd in wget tar killall; do
    if ! command -v $cmd >/dev/null 2>&1; then
        error "Commande manquante : $cmd"
        exit 1
    fi
done

# Répertoire de destination
DEST_DIR="/usr/lib/enigma2/python/Plugins/Extensions"

# Vérifier/créer le répertoire
if [ ! -d "$DEST_DIR" ]; then
    warn "Le répertoire $DEST_DIR n'existe pas."
    printf "Voulez-vous le créer ? (o/n) "
    read reponse
    if [ "$reponse" = "o" ] || [ "$reponse" = "O" ]; then
        mkdir -p "$DEST_DIR" || { error "Échec création répertoire"; exit 1; }
        success "Répertoire créé."
    else
        error "Installation annulée."
        exit 1
    fi
fi

# Vérifier espace disque
TMP_AVAIL=$(df /tmp | awk 'NR==2 {print $4}')
if [ "$TMP_AVAIL" -lt 10240 ]; then
    error "Espace insuffisant dans /tmp (<10 Mo)."
    exit 1
fi

DEST_AVAIL=$(df "$DEST_DIR" | awk 'NR==2 {print $4}')
if [ "$DEST_AVAIL" -lt 10240 ]; then
    error "Espace insuffisant dans $DEST_DIR (<10 Mo)."
    exit 1
fi

# Confirmation globale
echo
info "Ce script va installer le plugin UnionStream."
info "Source : https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz"
info "Destination : $DEST_DIR"
warn "Attention : Enigma2 sera tué (kill -9) mais pas redémarré automatiquement."
printf "Voulez-vous continuer ? (o/n) "
read reponse
if [ "$reponse" != "o" ] && [ "$reponse" != "O" ]; then
    info "Installation annulée."
    exit 0
fi

# Téléchargement
info "Téléchargement..."
wget -O /tmp/UnionStream.tar.gz https://github.com/Said-Pro/Union/raw/refs/heads/main/UnionStream.tar.gz
if [ $? -ne 0 ] || [ ! -f /tmp/UnionStream.tar.gz ]; then
    error "Échec du téléchargement."
    exit 1
fi
success "Téléchargé."

# Extraction
info "Extraction..."
cd /tmp/
tar -xzf UnionStream.tar.gz -C "$DEST_DIR"
if [ $? -ne 0 ]; then
    error "Échec de l'extraction."
    rm -f /tmp/UnionStream.tar.gz
    exit 1
fi
success "Extrait."

# Lister fichiers
info "Fichiers installés :"
ls -la "$DEST_DIR" | grep -E "Union|Stream" 2>/dev/null || echo "Aucun fichier visible."

# Nettoyage
rm -f /tmp/UnionStream.tar.gz
success "Nettoyage effectué."

# Arrêt d'Enigma2
warn "Arrêt d'Enigma2 (kill -9)."
printf "Confirmer ? (o/n) "
read reponse
if [ "$reponse" = "o" ] || [ "$reponse" = "O" ]; then
    killall -9 enigma2
    if [ $? -eq 0 ]; then
        success "Enigma2 arrêté."
    else
        warn "Échec du kill (peut-être déjà arrêté)."
    fi
else
    warn "Arrêt annulé."
fi

echo
success "Installation terminée."
info "Redémarrez Enigma2 manuellement (systemctl restart enigma2 ou reboot)."
