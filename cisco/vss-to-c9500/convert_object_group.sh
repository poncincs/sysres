#!/usr/bin/env bash
# ==============================================================================
# Nom        : convert_object_group.sh
# Description: Conversion IOS classique -> IOS-XE (C9500)
# Convertit : object-group ip address -> object-group network
#             host-info              -> host
#             addrgroup              -> object-group
# Usage      : ./convert_object_group.sh <fichier_source> [fichier_sortie]
# Auteur     : Samuel PONCIN CHAPERON
# Date       : 16-06-2026
# Version    : 1.0.0
# ==============================================================================

set -euo pipefail

# --- Couleurs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# --- Vérification arguments ---
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

echo -e "${BOLD}${CYAN}=== Conversion IOS -> IOS-XE ===${NC}"
echo -e "  Source  : ${YELLOW}$INPUT${NC}"
echo -e "  Sortie  : ${YELLOW}$OUTPUT${NC}"
echo ""

# --- Compteurs ---
count_og=0
count_host=0
count_addr=0

# --- Conversion ---
converted=$(awk '
{
    line = $0

    # object-group ip address NAME -> object-group network NAME
    if (line ~ /^object-group ip address /) {
        sub(/^object-group ip address /, "object-group network ", line)
        og_count++
    }

    # host-info X.X.X.X -> host X.X.X.X
    if (line ~ /^ *host-info /) {
        sub(/host-info /, "host ", line)
        host_count++
    }

    # addrgroup NAME -> object-group NAME (dans les ACL)
    if (line ~ /addrgroup /) {
        gsub(/addrgroup /, "object-group ", line)
        addr_count++
    }

    print line
}
END {
    print "#STATS:" og_count ":" host_count ":" addr_count
}
' "$INPUT")

# --- Extraction des stats ---
stats_line=$(echo "$converted" | grep "^#STATS:")
count_og=$(echo "$stats_line" | cut -d: -f2)
count_host=$(echo "$stats_line" | cut -d: -f3)
count_addr=$(echo "$stats_line" | cut -d: -f4)

# --- Écriture du fichier de sortie (sans la ligne de stats) ---
echo "$converted" | grep -v "^#STATS:" > "$OUTPUT"

# --- Affichage du résultat dans le terminal ---
echo -e "${BOLD}=== Fichier converti ===${NC}"
echo ""
grep -v "^#STATS:" <<< "$converted"
echo ""

# --- Résumé ---
echo -e "${BOLD}${CYAN}=== Résumé ===${NC}"
echo -e "  ${GREEN}✔ object-group ip address -> object-group network${NC} : ${BOLD}$count_og${NC} remplacement(s)"
echo -e "  ${GREEN}✔ host-info -> host${NC}                               : ${BOLD}$count_host${NC} remplacement(s)"
echo -e "  ${GREEN}✔ addrgroup -> object-group${NC}                       : ${BOLD}$count_addr${NC} remplacement(s)"
echo ""
echo -e "  Fichier généré : ${YELLOW}${OUTPUT}${NC}"
echo -e "${BOLD}${GREEN}=== Terminé ===${NC}"
