# ⚙️ sysres

> Collection de scripts système et réseau pour Linux — administration, automatisation et configuration de serveurs.

---

## 📁 Structure du repo

```bash
sysres/
├── README.md
├── users/
│   ├── README.md
│   └── mkusr.sh
└── cisco/
    └── vss-to-c9500/
        ├── README.md
        ├── convert_object_group.sh
        ├── convert_interfaces.sh
        ├── convert_vrf.sh
        ├── convert_acl.sh
        └── convert_cleanup.sh
```

> D'autres catégories seront ajoutées au fil du temps (monitoring, sécurité, etc.)

---

## 📂 Catégories

| Dossier | Description |
| --- | --- |
| [`users/`](./users/) | Gestion des utilisateurs Linux (création, permissions, environnement) |
| [`cisco/vss-to-c9500/`](./cisco/vss-to-c9500/) | Scripts de conversion de configuration Cisco VSS (IOS classique) vers Catalyst 9500 StackWise (IOS-XE) |

---

## 🚀 Utilisation générale

Cloner le repo :

```bash
git clone https://github.com/<votre-username>/sysres.git
cd sysres
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

---

## ✍ Auteur

Créé et maintenu par **Samuel PONCIN CHAPERON**
