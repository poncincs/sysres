#!/usr/bin/env bash
# ==============================================================================
# Nom        : convert_acl.sh
# Description: Conversion ACL numérotées -> nommées IOS-XE (C9500)
#
# Conversions effectuées :
#   access-list 1-99    -> ip access-list standard ACL_<num>
#   access-list 100-199 -> ip access-list extended ACL_<num>
#
# Usage      : ./convert_acl.sh <fichier_source> [fichier_sortie]
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

echo -e "${BOLD}${CYAN}=== Conversion ACL numérotées -> nommées IOS-XE ===${NC}"
echo -e "  Source  : ${YELLOW}$INPUT${NC}"
echo -e "  Sortie  : ${YELLOW}$OUTPUT${NC}"
echo ""

converted=$(gawk '
BEGIN {
    current_acl = ""
    std_count = 0
    ext_count = 0
}
{
    line = $0

    if (match(line, /^access-list ([0-9]+) (permit|deny) (.*)/, arr)) {
        num  = arr[1] + 0
        action = arr[2]
        rest   = arr[3]

        if ((num >= 1 && num <= 99) || (num >= 1300 && num <= 1999)) {
            type = "standard"
        } else {
            type = "extended"
        }

        acl_name = "ACL_" num

        if (acl_name != current_acl) {
            current_acl = acl_name
            print "ip access-list " type " " acl_name
            if (type == "standard") std_count++
            else ext_count++
        }

        print " " action " " rest
        next
    }

    current_acl = ""
    print line
}
END {
    print "#STATS:" std_count ":" ext_count
}
' "$INPUT")

stats_line=$(echo "$converted" | grep "^#STATS:")
count_std=$(echo "$stats_line" | cut -d: -f2)
count_ext=$(echo "$stats_line" | cut -d: -f3)

echo "$converted" | grep -v "^#STATS:" > "$OUTPUT"

echo -e "${BOLD}=== Fichier converti ===${NC}"
echo ""
grep -v "^#STATS:" <<< "$converted"
echo ""

echo -e "${BOLD}${CYAN}=== Résumé ===${NC}"
echo -e "  ${GREEN}✔ ACL standard converties${NC}  : ${BOLD}$count_std${NC}"
echo -e "  ${GREEN}✔ ACL extended converties${NC}  : ${BOLD}$count_ext${NC}"
echo -e "  Fichier généré : ${YELLOW}${OUTPUT}${NC}"
echo -e "${BOLD}${GREEN}=== Terminé ===${NC}"
