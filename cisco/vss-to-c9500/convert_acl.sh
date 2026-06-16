#!/bin/bash
# =============================================================================
# convert_acl.sh - Conversion ACL numérotées -> nommées IOS-XE (C9500)
#
# Conversions effectuées :
#   access-list 1-99    -> ip access-list standard ACL_<num>
#   access-list 100-199 -> ip access-list extended ACL_<num>
#
# Usage : ./convert_acl.sh <fichier_source> [fichier_sortie]
# =============================================================================

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

current_acl=""
count_std=0
count_ext=0
tmpfile=$(mktemp)

while IFS= read -r line; do
    # Ligne de type : access-list <num> permit|deny <reste>
    if echo "$line" | grep -qE '^access-list [0-9]+ (permit|deny) '; then
        num=$(echo "$line"    | awk '{print $2}')
        action=$(echo "$line" | awk '{print $3}')
        rest=$(echo "$line"   | awk '{$1=$2=$3=""; sub(/^[[:space:]]+/,""); print}')

        if { [[ $num -ge 1 && $num -le 99 ]] || [[ $num -ge 1300 && $num -le 1999 ]]; }; then
            type="standard"
        else
            type="extended"
        fi

        acl_name="ACL_${num}"

        if [[ "$acl_name" != "$current_acl" ]]; then
            current_acl="$acl_name"
            echo "ip access-list ${type} ${acl_name}" >> "$tmpfile"
            if [[ "$type" == "standard" ]]; then
                count_std=$((count_std+1))
            else
                count_ext=$((count_ext+1))
            fi
        fi

        echo " ${action} ${rest}" >> "$tmpfile"
    else
        current_acl=""
        echo "$line" >> "$tmpfile"
    fi
done < "$INPUT"

cp "$tmpfile" "$OUTPUT"
rm "$tmpfile"

echo -e "${BOLD}=== Fichier converti ===${NC}"
echo ""
cat "$OUTPUT"
echo ""

echo -e "${BOLD}${CYAN}=== Résumé ===${NC}"
echo -e "  ${GREEN}✔ ACL standard converties${NC}  : ${BOLD}$count_std${NC}"
echo -e "  ${GREEN}✔ ACL extended converties${NC}  : ${BOLD}$count_ext${NC}"
echo -e "  Fichier généré : ${YELLOW}${OUTPUT}${NC}"
echo -e "${BOLD}${GREEN}=== Terminé ===${NC}"
