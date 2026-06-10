#!/bin/bash
# =============================================================================
# Script  : mkusr.sh
# Author  : Samuel PONCIN CHAPERON
# Date    : 2026-06-05
# Version : 2.2.0
# Description : Crée un utilisateur Linux avec bash, dossier SSH et PS1
#               coloré selon le profil (user, critical, root).
# =============================================================================

set -euo pipefail

# --- Couleurs pour l'affichage du script lui-même ---
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
ORANGE=$'\033[0;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'

myself=$(basename "$0")

display() { printf -- "%s\n" "$1"; }

error() {
	display "Erreur: $1" >&2
	[ "${3-}" == true ] && usage
	[ -n "${2-}" ] && exit "$2"
}

# --- Usage ---
usage() {
	cat <<- EOF

	${BOLD}NOM${NC}
	    $myself — Création d'un utilisateur Linux avec environnement bash personnalisé

	${BOLD}SYNOPSIS${NC}
	    ${CYAN}./$myself${NC} ${BOLD}-u <username>${NC} ${BOLD}-p <password>${NC} ${BOLD}-t <type>${NC} [${BOLD}-H <hostname>${NC}]
	    ${CYAN}./$myself${NC} ${BOLD}-h${NC}

	${BOLD}OPTIONS${NC}
	    ${BOLD}-u <username>${NC}   Nom de l'utilisateur à créer ${BOLD}(obligatoire)${NC}
	    ${BOLD}-p <password>${NC}   Mot de passe de l'utilisateur ${BOLD}(obligatoire)${NC}
	    ${BOLD}-t <type>${NC}       Profil de couleur du PS1 ${BOLD}(obligatoire)${NC} :
	                    ${GREEN}user${NC}      → username@hostname en vert     (PC / serveur standard)
	                    ${ORANGE}critical${NC}  → username@hostname en orange   (serveur critique)
	                    ${RED}root${NC}      → username@hostname en rouge    (compte root)
	    ${BOLD}-H <hostname>${NC}   Hostname affiché dans le PS1 (optionnel, défaut : hostname système)
	    ${BOLD}-h${NC}              Affiche cette aide et quitte

	${BOLD}EXEMPLES${NC}
	    ${CYAN}./$myself${NC} -u jdupont -p Passw0rd -t user
	    ${CYAN}./$myself${NC} -u deploy  -p Passw0rd -t critical -H prod-db-01
	    ${CYAN}./$myself${NC} -u root    -p Passw0rd -t root

	${BOLD}RÉSULTAT DES PROFILS PS1${NC}
	    user     →  ${GREEN}jdupont${NC}@${GREEN}serveur${NC}:${BLUE}/home/jdupont${NC}\$
	    critical →  ${ORANGE}deploy${NC}@${ORANGE}prod-db-01${NC}:${BLUE}/home/deploy${NC}\$
	    root     →  ${RED}root${NC}@${RED}serveur${NC}:${BLUE}/root${NC}#

	EOF
}

# --- Vérification root ---
check_root() {
	if [[ "$EUID" -ne 0 ]]; then
		error "Ce script doit être exécuté en tant que root." 1
	fi
}

# --- Parsing des arguments ---
USERNAME=""
PASSWORD=""
TYPE=""
HOSTNAME_OVERRIDE=""

while getopts "u:p:t:H:h" opt; do
	case "$opt" in
		u) USERNAME="$OPTARG" ;;
		p) PASSWORD="$OPTARG" ;;
		t) TYPE="$OPTARG" ;;
		H) HOSTNAME_OVERRIDE="$OPTARG" ;;
		h) usage; exit 0 ;;
		*) usage; exit 1 ;;
	esac
done

# --- Validation des arguments obligatoires ---
if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$TYPE" ]]; then
	error "Les options -u, -p et -t sont obligatoires." 1 true
fi

if [[ "$TYPE" != "user" && "$TYPE" != "critical" && "$TYPE" != "root" ]]; then
	error "Type invalide : '$TYPE'. Valeurs acceptées : user, critical, root." 1 true
fi

# --- Définition du PS1 selon le profil ---
case "$TYPE" in
	user)
		PS1_VALUE='\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '
		PROFILE_LABEL="${GREEN}user${NC}"
		;;
	critical)
		PS1_VALUE='\[\e[0;33m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '
		PROFILE_LABEL="${ORANGE}critical${NC}"
		;;
	root)
		PS1_VALUE='\[\e[0;31m\]\u@\h\[\e[0m\]:\[\e[0;34m\]\w\[\e[0m\]\$ '
		PROFILE_LABEL="${RED}root${NC}"
		;;
esac

# --- Création de l'utilisateur ---
check_root

cat <<- EOF

	${BOLD}[ mkusr.sh ]${NC} Création de l'utilisateur ${CYAN}$USERNAME${NC} (profil : $(printf "$PROFILE_LABEL"))

EOF

# Vérifier si l'utilisateur existe déjà
if id "$USERNAME" &>/dev/null; then
	error "L'utilisateur '$USERNAME' existe déjà." 1
fi

# Créer l'utilisateur avec bash comme shell
useradd -m -s /bin/bash "$USERNAME"
cat <<- EOF
	${GREEN}[OK]${NC}     Utilisateur '$USERNAME' créé avec /bin/bash
EOF

# Définir le mot de passe
echo "$USERNAME:$PASSWORD" | chpasswd
cat <<- EOF
	${GREEN}[OK]${NC}     Mot de passe défini
EOF

# Créer le dossier .ssh avec les bonnes permissions
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
cat <<- EOF
	${GREEN}[OK]${NC}     Dossier .ssh créé avec les bonnes permissions
EOF

# Appliquer le hostname override si fourni
HOSTNAME_LINE=""
if [[ -n "$HOSTNAME_OVERRIDE" ]]; then
	HOSTNAME_LINE="export HOSTNAME_DISPLAY=\"$HOSTNAME_OVERRIDE\""
fi

# Écrire le PS1 et les alias dans le .bashrc
cat >> /home/$USERNAME/.bashrc << EOF

# --- PS1 personnalisé (mkusr.sh - profil : $TYPE) ---
$HOSTNAME_LINE
export PS1='$PS1_VALUE'

# --- Alias (mkusr.sh) ---
alias l='ls -lha --color=auto'
alias grep='grep --color=auto'
EOF

chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc
cat <<- EOF
	${GREEN}[OK]${NC}     PS1 personnalisé appliqué (profil : $(printf "$PROFILE_LABEL"))
	${GREEN}[OK]${NC}     Alias ajoutés (l, grep)
EOF

cat <<- EOF

	${BOLD}${GREEN}[ SUCCÈS ]${NC} L'utilisateur ${CYAN}$USERNAME${NC} est prêt.
	           Shell   : /bin/bash
	           Home    : /home/$USERNAME
	           SSH     : /home/$USERNAME/.ssh/authorized_keys
	           Profil  : $(printf "$PROFILE_LABEL")
	           Alias   : l='ls -lha --color=auto'  |  grep='grep --color=auto'

EOF
