# cisco_iface_convert.sh

Script bash de conversion des noms d'interfaces Cisco lors d'une migration **VSS → StackWise**.

---

## Contexte

Les anciens switches Cisco en mode **VSS** (Virtual Switching System) utilisent un nommage à trois niveaux :

```
{Type}{switch}/{module}/{port}

Exemples :
  TenGigabitEthernet1/1/2
  GigabitEthernet2/6/1
```

Les nouveaux switches **Cisco Catalyst 9500** en mode **StackWise** utilisent un nommage à deux niveaux, tous les ports étant de type `TwentyFiveGigE` :

```
TwentyFiveGigE{switch}/0/{port}

Exemples :
  TwentyFiveGigE1/0/2
  TwentyFiveGigE2/0/1
```

Ce script automatise la substitution dans un fichier de configuration IOS.

---

## Règle de mapping

| Composant VSS     | Composant StackWise | Détail                              |
|-------------------|---------------------|-------------------------------------|
| Type d'interface  | `TwentyFiveGigE`    | Tous les types sont normalisés      |
| Numéro de switch  | Numéro de switch    | Conservé tel quel (`1` ou `2`)      |
| Numéro de module  | `0`                 | Supprimé, remplacé par `0` (fixe)   |
| Numéro de port    | Numéro de port      | Conservé tel quel                   |

```
TenGigabitEthernet1 / 3 / 1
                    |   |   |
                  switch|  port
                      module (supprimé)
                          ↓
           TwentyFiveGigE1/0/1
```

Types d'interfaces reconnus et convertis :
- `GigabitEthernet`
- `TenGigabitEthernet`
- `FortyGigabitEthernet`
- `HundredGigE`
- `TwentyFiveGigE` (idempotent — déjà au bon format)

---

## Utilisation

Rendre le script exécutable (une seule fois) :

```bash
chmod +x cisco_iface_convert.sh
```

### Mode 1 — Aperçu sans modification

Affiche le résultat converti sur la sortie standard, sans toucher au fichier source :

```bash
./cisco_iface_convert.sh running-config.txt
```

Utile pour vérifier le résultat avant de l'appliquer.

### Mode 2 — Modification en place

Modifie directement le fichier source. Une copie de sauvegarde `.bak` est créée automatiquement :

```bash
./cisco_iface_convert.sh running-config.txt -i
# → crée running-config.txt.bak
# → modifie running-config.txt
```

### Mode 3 — Écriture dans un nouveau fichier

Conserve le fichier source intact et écrit le résultat dans un nouveau fichier :

```bash
./cisco_iface_convert.sh running-config.txt -o new-config.txt
```

---

## Exemple concret

**Fichier d'entrée** (`running-config.txt`) :

```
interface TenGigabitEthernet1/1/2
 description uplink-core
interface GigabitEthernet1/3/1
 switchport mode access
interface TenGigabitEthernet2/6/4
 channel-group 2 mode active
```

**Commande :**

```bash
./cisco_iface_convert.sh running-config.txt
```

**Sortie :**

```
interface TwentyFiveGigE1/0/2
 description uplink-core
interface TwentyFiveGigE1/0/1
 switchport mode access
interface TwentyFiveGigE2/0/4
 channel-group 2 mode active
```

---

## Fonctionnement interne

### Sécurités bash (`set -euo pipefail`)

Le script commence par :

```bash
set -euo pipefail
```

| Option | Effet |
|--------|-------|
| `-e`   | Arrête le script dès qu'une commande échoue |
| `-u`   | Erreur si une variable non définie est utilisée |
| `-o pipefail` | Propage les erreurs au sein des pipes |

### L'expression `sed`

```
s/\(GigabitEthernet\|TenGigabitEthernet\|...\)\([0-9]\+\)\/[0-9]\+\/\([0-9]\+\)/TwentyFiveGigE\2\/0\/\3/g
```

Décomposée en groupes de capture :

```
\(GigabitEthernet\|TenGigabitEthernet\|...\)   → \1 : type d'interface  (ignoré en sortie)
\([0-9]\+\)                                     → \2 : numéro de switch  (réutilisé)
\/[0-9]\+\/                                     →      numéro de module   (supprimé)
\([0-9]\+\)                                     → \3 : numéro de port    (réutilisé)
```

Remplacement : `TwentyFiveGigE\2\/0\/\3`

Le flag `g` en fin d'expression garantit que **toutes** les occurrences sur une même ligne sont traitées (utile si une ligne de config référence plusieurs interfaces).

### Gestion des modes

```bash
case "$MODE" in
    stdout)  sed "$SED_EXPR" "$INPUT" ;;
    inplace) cp "$INPUT" "${INPUT}.bak" && sed -i "$SED_EXPR" "$INPUT" ;;
    output)  sed "$SED_EXPR" "$INPUT" > "$OUTPUT" ;;
esac
```

En mode `inplace`, la copie `.bak` est effectuée **avant** l'appel à `sed -i` pour garantir qu'une sauvegarde existe même en cas d'erreur.

---

## Limitations

- Le script ne valide pas que les numéros de port correspondent à des ports physiques existants sur le C9500 — c'est à vérifier manuellement.
- Les alias d'interfaces (ex: `Te1/1/2` au lieu de `TenGigabitEthernet1/1/2`) ne sont **pas** convertis. Si ta config en contient, il faudra ajouter les formes courtes à l'expression `sed`.
