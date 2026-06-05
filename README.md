# ⚙️ sysforge

> Collection de scripts système et réseau pour Linux — administration, automatisation et configuration de serveurs.

Créé et maintenu par **Samuel PONCIN CHAPERON**

---

## 📁 Structure du repo

```
sysforge/
├── README.md
└── users/
    ├── README.md
    └── mkusr.sh
```

> D'autres catégories seront ajoutées au fil du temps (réseau, monitoring, sécurité, etc.)

---

## 📂 Catégories

| Dossier | Description |
|---|---|
| [`users/`](./users/) | Gestion des utilisateurs Linux (création, permissions, environnement) |

---

## 🚀 Utilisation générale

Cloner le repo :

```bash
git clone https://github.com/<votre-username>/sysforge.git
cd sysforge
```

Rendre un script exécutable :

```bash
chmod +x <dossier>/<script>.sh
./<dossier>/<script>.sh -h
```

---

## 🛠️ Environnement cible

- Debian / Ubuntu (testé sur Debian Trixie)
- Bash 5+
- Droits root requis pour la plupart des scripts

---

## 📜 Licence

Ce projet est distribué sous licence MIT. Voir [`LICENSE`](./LICENSE) pour plus d'informations.

---

## 🤝 Contribution

Les issues et pull requests sont les bienvenues.  
Pour toute suggestion, ouvrir une issue en décrivant le besoin.
