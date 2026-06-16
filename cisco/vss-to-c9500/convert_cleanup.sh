#!/usr/bin/env bash
# ==============================================================================
# Nom        : convert_cleanup.sh
# Description: Suppression des commandes obsolètes sur IOS-XE (C9500)
#
# Commandes supprimées/converties :
#   ip classless, ip subnet-zero, ip default-network  -> supprimées
#   logging X.X.X.X                                   -> logging host X.X.X.X
#   logging on                                        -> commentée
#   spanning-tree mode pvst                           -> rapid-pvst
#   ip nat pool ... netmask                           -> prefix-length
#
# Usage      : ./convert_cleanup.sh <fichier_source> [fichier_sortie]
# Auteur     : Samuel PONCIN CHAPERON
# Date       : 16-06-2026
# Version    : 1.0.0
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [[ $# -lt 1 ]]; then
    echo -e "${RED}Usage : $0 <fichier_source> [fichier_sortie]${NC}"
    exit 1
fi

INPUT="$1"
OUTPUT="${2:-${INPUT%.conf}_iosxe.conf}"

if [[ ! -f "$INPUT" ]]; then
    echo -e "${RED}Erreur : fichier introuvable : $INPUT${NC}"
    exit 1
fi

echo -e "${BOLD}${CYAN}=== Nettoyage commandes obsolètes -> IOS-XE ===${NC}"
echo -e "  Source  : ${YELLOW}$INPUT${NC}"
echo -e "  Sortie  : ${YELLOW}$OUTPUT${NC}"
echo ""

# Fonction de conversion masque -> prefix-length
mask_to_prefix() {
    local mask="$1"
    case "$mask" in
        255.255.255.255) echo 32 ;;
        255.255.255.254) echo 31 ;;
        255.255.255.252) echo 30 ;;
        255.255.255.248) echo 29 ;;
        255.255.255.240) echo 28 ;;
        255.255.255.224) echo 27 ;;
        255.255.255.192) echo 26 ;;
        255.255.255.128) echo 25 ;;
        255.255.255.0)   echo 24 ;;
        255.255.254.0)   echo 23 ;;
        255.255.252.0)   echo 22 ;;
        255.255.248.0)   echo 21 ;;
        255.255.240.0)   echo 20 ;;
        255.255.224.0)   echo 19 ;;
        255.255.192.0)   echo 18 ;;
        255.255.128.0)   echo 17 ;;
        255.255.0.0)     echo 16 ;;
        255.254.0.0)     echo 15 ;;
        255.252.0.0)     echo 14 ;;
        255.0.0.0)       echo 8  ;;
        *) echo "" ;;
    esac
}

removed_count=0
logging_count=0
stp_count=0
nat_count=0

tmpfile=$(mktemp)

while IFS= read -r line; do
    # Commandes obsolètes -> supprimées (commentées)
    if echo "$line" | grep -qE '^(no )?(ip classless|ip subnet-zero|ip default-network)'; then
        echo "! [SUPPRIMÉ] $line" >> "$tmpfile"
        removed_count=$((removed_count+1))
        continue
    fi

    # logging on -> commenté
    if echo "$line" | grep -qE '^logging on$'; then
        echo "! [SUPPRIMÉ] $line" >> "$tmpfile"
        logging_count=$((logging_count+1))
        continue
    fi

    # logging X.X.X.X -> logging host X.X.X.X
    if echo "$line" | grep -qE '^logging [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then
        line=$(echo "$line" | sed 's/^logging /logging host /')
        logging_count=$((logging_count+1))
    fi

    # spanning-tree mode pvst -> rapid-pvst
    if echo "$line" | grep -q 'spanning-tree mode pvst'; then
        line=$(echo "$line" | sed 's/pvst/rapid-pvst/')
        stp_count=$((stp_count+1))
    fi

    # ip nat pool ... netmask X -> prefix-length N
    if echo "$line" | grep -qE 'ip nat pool .* netmask '; then
        mask=$(echo "$line" | grep -oE 'netmask ([0-9.]+)' | awk '{print $2}')
        prefix=$(mask_to_prefix "$mask")
        if [[ -n "$prefix" ]]; then
            line=$(echo "$line" | sed "s/netmask $mask/prefix-length $prefix/")
            nat_count=$((nat_count+1))
        fi
    fi

    echo "$line" >> "$tmpfile"
done < "$INPUT"

cp "$tmpfile" "$OUTPUT"
rm "$tmpfile"

echo -e "${BOLD}=== Fichier converti ===${NC}"
echo ""
cat "$OUTPUT"
echo ""

echo -e "${BOLD}${CYAN}=== Résumé ===${NC}"
echo -e "  ${GREEN}✔ Commandes obsolètes supprimées${NC}        : ${BOLD}$removed_count${NC}"
echo -e "  ${GREEN}✔ logging -> logging host${NC}               : ${BOLD}$logging_count${NC} remplacement(s)"
echo -e "  ${GREEN}✔ spanning-tree pvst -> rapid-pvst${NC}      : ${BOLD}$stp_count${NC} remplacement(s)"
echo -e "  ${GREEN}✔ nat pool netmask -> prefix-length${NC}     : ${BOLD}$nat_count${NC} remplacement(s)"
echo ""
echo -e "  ${YELLOW}⚠ Les lignes supprimées sont commentées avec [SUPPRIMÉ] dans le fichier de sortie${NC}"
echo -e "  Fichier généré : ${YELLOW}${OUTPUT}${NC}"
echo -e "${BOLD}${GREEN}=== Terminé ===${NC}"
