# 👤 users/

> Scripts de gestion des utilisateurs Linux : création, configuration de l'environnement bash, permissions SSH.

---

## 📄 Scripts disponibles

### `mkusr.sh`

Crée un utilisateur Linux complet avec :

- **Shell** bash par défaut
- **Dossier `.ssh`** et fichier `authorized_keys` avec les permissions correctes
- **PS1 coloré** selon le profil du serveur/utilisateur

#### Profils de couleur disponibles

| Profil | Couleur | Usage typique |
| --- | --- | --- |
| `user` | 🟢 Vert | Utilisateur standard sur PC ou serveur classique |
| `critical` | 🟠 Orange | Utilisateur sur un serveur critique (prod, base de données…) |
| `root` | 🔴 Rouge | Compte root ou administrateur |

Le **répertoire courant** est toujours affiché en **bleu** quel que soit le profil.

#### Synopsis

```bash
./mkusr.sh -u <username> -p <password> -t <type> [-H <hostname>]
./mkusr.sh -h
```

#### Options

| Option | Description | Obligatoire |
| --- | --- | --- |
| `-u <username>` | Nom de l'utilisateur à créer | ✅ |
| `-p <password>` | Mot de passe de l'utilisateur | ✅ |
| `-t <type>` | Profil PS1 : `user`, `critical`, `root` | ✅ |
| `-H <hostname>` | Hostname custom affiché dans le prompt | ❌ |
| `-h` | Affiche l'aide | ❌ |

#### Exemples

```bash
# Utilisateur standard
./mkusr.sh -u jdupont -p Passw0rd -t user

# Utilisateur sur serveur critique avec hostname personnalisé
./mkusr.sh -u deploy -p Passw0rd -t critical -H prod-db-01

# Compte root
./mkusr.sh -u root -p Passw0rd -t root
```

#### Ce que le script crée

```bash
/home/<username>/
├── .ssh/
│   └── authorized_keys   (chmod 600)
└── .bashrc               (PS1 personnalisé + alias ajouté)
```

#### Prérequis

- Être exécuté en **root**
- Bash 5+
- Debian / Ubuntu

---

## ✍️ Auteur

**Samuel PONCIN CHAPERON** — 2026
