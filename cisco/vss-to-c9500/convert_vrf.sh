#!/usr/bin/env bash
# ==============================================================================
# Nom        : convert_vrf.sh
# Description: Conversion VRF IOS classique -> IOS-XE (C9500)
#
# Conversions effectuées :
#   ip vrf NAME          -> vrf definition NAME
#   ip vrf forwarding    -> vrf forwarding  (sur les interfaces)
#   + ajout du bloc address-family ipv4 / exit-address-family
#
# Usage : ./convert_vrf.sh <fichier_source> [fichier_sortie]
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

echo -e "${BOLD}${CYAN}=== Conversion VRF IOS -> IOS-XE ===${NC}"
echo -e "  Source  : ${YELLOW}$INPUT${NC}"
echo -e "  Sortie  : ${YELLOW}$OUTPUT${NC}"
echo ""

converted=$(awk '
{
    line = $0

    # Détection du bloc "ip vrf NAME" -> "vrf definition NAME"
    # On injecte le bloc address-family après le contenu du bloc vrf
    if (line ~ /^ip vrf /) {
        sub(/^ip vrf /, "vrf definition ", line)
        in_vrf = 1
        vrf_count++
        print line
        next
    }

    # Fin du bloc vrf (ligne vide ou nouvelle section)
    if (in_vrf && (line ~ /^[^ !]/ || line == "")) {
        if (!af_added) {
            print " address-family ipv4"
            print " exit-address-family"
        }
        in_vrf = 0
        af_added = 0
    }

    # Si on est dans un bloc vrf et quil y a deja un address-family
    if (in_vrf && line ~ /address-family/) {
        af_added = 1
    }

    # ip vrf forwarding -> vrf forwarding (sur les interfaces)
    if (line ~ /ip vrf forwarding /) {
        sub(/ip vrf forwarding /, "vrf forwarding ", line)
        fwd_count++
    }

    print line
}
END {
    # Si le fichier se termine dans un bloc vrf
    if (in_vrf && !af_added) {
        print " address-family ipv4"
        print " exit-address-family"
    }
    print "#STATS:" vrf_count ":" fwd_count
}
' "$INPUT")

stats_line=$(echo "$converted" | grep "^#STATS:")
count_vrf=$(echo "$stats_line" | cut -d: -f2)
count_fwd=$(echo "$stats_line" | cut -d: -f3)

echo "$converted" | grep -v "^#STATS:" > "$OUTPUT"

echo -e "${BOLD}=== Fichier converti ===${NC}"
echo ""
grep -v "^#STATS:" <<< "$converted"
echo ""

echo -e "${BOLD}${CYAN}=== Résumé ===${NC}"
echo -e "  ${GREEN}✔ ip vrf NAME -> vrf definition NAME${NC}   : ${BOLD}$count_vrf${NC} remplacement(s)"
echo -e "  ${GREEN}✔ ip vrf forwarding -> vrf forwarding${NC}  : ${BOLD}$count_fwd${NC} remplacement(s)"
echo -e "  Fichier généré : ${YELLOW}${OUTPUT}${NC}"
echo -e "${BOLD}${GREEN}=== Terminé ===${NC}"
