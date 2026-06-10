#!/usr/bin/env bash
# ============================================================
# cisco_iface_convert.sh
# Convertit les noms d'interfaces Cisco VSS vers StackWise
#
# Règle de mapping :
#   {Type}{switch}/{module}/{port}  →  TwentyFiveGigE{switch}/0/{port}
#
# Types supportés (insensible à la casse) :
#   GigabitEthernet, TenGigabitEthernet, HundredGigE, FortyGigabitEthernet, etc.
#
# Usage :
#   ./cisco_iface_convert.sh <fichier_config>          # affiche le résultat
#   ./cisco_iface_convert.sh <fichier_config> -i       # modifie le fichier en place
#   ./cisco_iface_convert.sh <fichier_config> -o <out> # écrit dans un nouveau fichier
# ============================================================

set -euo pipefail

usage() {
    echo "Usage: $0 <fichier_config> [-i | -o <fichier_sortie>]"
    echo ""
    echo "  Sans option    : affiche le résultat sur stdout"
    echo "  -i             : modifie le fichier en place (crée un .bak)"
    echo "  -o <fichier>   : écrit le résultat dans <fichier>"
    exit 1
}

[[ $# -lt 1 ]] && usage

INPUT="$1"
MODE="stdout"
OUTPUT=""

[[ ! -f "$INPUT" ]] && { echo "Erreur : fichier '$INPUT' introuvable."; exit 1; }

if [[ $# -ge 2 ]]; then
    case "$2" in
        -i) MODE="inplace" ;;
        -o)
            [[ $# -lt 3 ]] && { echo "Erreur : -o requiert un nom de fichier."; usage; }
            MODE="output"
            OUTPUT="$3"
            ;;
        *) usage ;;
    esac
fi

# Expression sed :
#   Capture :  (Type)(switch)/(module)/(port)
#   Restitue : TwentyFiveGigE\2/0/\4
#
# Le groupe 1 capture le nom du type d'interface (ignoré dans la sortie).
# Le groupe 2 capture le numéro de switch.
# Le groupe 3 capture le numéro de module (ignoré dans la sortie).
# Le groupe 4 capture le numéro de port.

SED_EXPR='s/\(GigabitEthernet\|TenGigabitEthernet\|HundredGigE\|FortyGigabitEthernet\|TwentyFiveGigE\)\([0-9]\+\)\/[0-9]\+\/\([0-9]\+\)/TwentyFiveGigE\2\/0\/\3/g'

case "$MODE" in
    stdout)
        sed "$SED_EXPR" "$INPUT"
        ;;
    inplace)
        cp "$INPUT" "${INPUT}.bak"
        sed -i "$SED_EXPR" "$INPUT"
        echo "Fichier modifié en place. Sauvegarde : ${INPUT}.bak"
        ;;
    output)
        sed "$SED_EXPR" "$INPUT" > "$OUTPUT"
        echo "Résultat écrit dans : $OUTPUT"
        ;;
esac
