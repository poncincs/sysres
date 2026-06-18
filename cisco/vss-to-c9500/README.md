# vss-to-c9500

Scripts de conversion de configuration Cisco IOS classique (VSS) vers IOS-XE (Catalyst 9500 StackWise).

---

## Arborescence

```bash
vss-to-c9500/
├── README.md
├── convert_object_group.sh   # Conversion des object-groups et ACL associées
├── convert_vrf.sh            # Conversion des définitions VRF
├── convert_acl.sh            # Conversion des ACL numérotées -> nommées
└── convert_cleanup.sh        # Suppression des commandes obsolètes
```

---

## Utilisation générale

Tous les scripts suivent la même syntaxe :

```bash
chmod +x <script>.sh
./<script>.sh <fichier_source.conf> [fichier_sortie.conf]
```

Si le fichier de sortie n'est pas précisé, le script génère automatiquement un fichier `<source>_iosxe.conf` dans le même répertoire.

> ⚠️ `convert_acl.sh` ne dépend que de bash/sed/grep/awk natifs — aucun paquet supplémentaire (type `gawk`) n'est requis.

---

## Scripts

### `convert_object_group.sh`

Convertit les object-groups et les références dans les ACL.

| Avant (IOS classique) | Après (IOS-XE) |
| --- | --- |
| `object-group ip address NOM` | `object-group network NOM` |
| `host-info x.x.x.x` | `host x.x.x.x` |
| `addrgroup NOM` | `object-group NOM` |

```bash
./convert_object_group.sh r-dsim-acl.conf
```

---

### `convert_vrf.sh`

Convertit les définitions VRF et leurs références sur les interfaces.

| Avant (IOS classique) | Après (IOS-XE) |
| --- | --- |
| `ip vrf MGMT` | `vrf definition MGMT` |
| `ip vrf forwarding MGMT` | `vrf forwarding MGMT` |
| *(pas de bloc address-family)* | `address-family ipv4` / `exit-address-family` ajouté automatiquement |

> ⚠️ Sur IOS-XE, `vrf forwarding` doit impérativement être configuré **avant** `ip address` sur une interface, sinon l'adresse IP est effacée automatiquement.

```bash
./convert_vrf.sh running-config.conf
```

---

### `convert_acl.sh`

Convertit les ACL numérotées (syntaxe IOS classique) en ACL nommées (syntaxe IOS-XE recommandée).

| Avant (IOS classique) | Après (IOS-XE) |
| --- | --- |
| `access-list 10 permit 192.168.1.0 0.0.0.255` | `ip access-list standard ACL_10` / `permit 192.168.1.0 0.0.0.255` |
| `access-list 100 permit tcp ...` | `ip access-list extended ACL_100` / `permit tcp ...` |

Plages supportées :

- Standard : 1–99 et 1300–1999
- Extended : 100–199 et 2000–2699

```bash
./convert_acl.sh running-config.conf
```

---

### `convert_cleanup.sh`

Supprime ou corrige les commandes qui n'existent plus sur IOS-XE.

| Commande | Action |
| --- | --- |
| `ip classless` | Supprimée (commentée `[SUPPRIMÉ]`) |
| `ip subnet-zero` | Supprimée (commentée `[SUPPRIMÉ]`) |
| `ip default-network` | Supprimée (commentée `[SUPPRIMÉ]`) |
| `logging on` | Supprimée (commentée `[SUPPRIMÉ]`) |
| `logging X.X.X.X` | Convertie en `logging host X.X.X.X` |
| `logging ip access-list cache ...` | Supprimée (commentée `[SUPPRIMÉ]`) — n'existe pas sur IOS-XE |
| `spanning-tree mode pvst` | Convertie en `spanning-tree mode rapid-pvst` |
| `ip nat pool ... netmask` | Convertie en `prefix-length` |
| `permit/deny icmp ... hoplimit` | Mot-clé `hoplimit` supprimé (non supporté sur IOS-XE) |

> Les lignes supprimées ne sont pas effacées du fichier de sortie mais **commentées** avec le tag `[SUPPRIMÉ]` pour garder une trace.

```bash
./convert_cleanup.sh running-config.conf
```

---

## Ordre d'exécution recommandé

Lors d'une migration complète, appliquer les scripts dans cet ordre :

```bash
1. convert_cleanup.sh        # Nettoyer les commandes obsolètes en premier
2. convert_vrf.sh            # VRF avant les interfaces
3. convert_object_group.sh   # Object-groups avant les ACL
4. convert_acl.sh            # ACL en dernier
```

Exemple en chaîne :

```bash
./convert_cleanup.sh        full-config.conf full-config-step1.conf
./convert_vrf.sh            full-config-step1.conf full-config-step2.conf
./convert_object_group.sh   full-config-step2.conf full-config-step3.conf
./convert_acl.sh            full-config-step3.conf full-config-final.conf
```

---

## Limitations connues

- **CBAC / `ip inspect`** : la migration vers le Zone-Based Firewall (ZBF) d'IOS-XE ne peut pas être automatisée. Une réécriture manuelle est nécessaire.
- Les scripts traitent les cas courants. Une relecture manuelle du fichier final avant application sur le switch est fortement recommandée.
- Toujours tester avec un `copy tftp running-config` sur un équipement de lab avant la production.
- Si une ACL du même nom existe déjà dans la running-config cible, le `copy tftp` peut générer des erreurs `Duplicate entry exists at sequence X`. Supprimer l'ACL existante avant import (`no ip access-list extended NOM_ACL`).

---

## Dépôt

Ces scripts font partie du dépôt `sysres`.
