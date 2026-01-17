# 🗺️ Roadmap - Wired Lamp Pillar Mod (8 jours)

```
┌─────────────────────────────────────────────────────────────┐
│           WIRED LAMP PILLAR - PROJECT ZOMBOID MOD           │
└─────────────────────────────────────────────────────────────┘

Semaine 1                           Semaine 2
├────┬────┬────┬────┬────┬────┬────┬────┤
│ J1 │ J2 │ J3 │ J4 │ J5 │ J6 │ J7 │ J8 │
└────┴────┴────┴────┴────┴────┴────┴────┘
Setup     Core    Polish  Test   Release
  +       Élec      +      +       +
Assets             UX    Compat   Doc
```

---

## **Jour 1-2 : Fondations**
### Setup & Assets (Journées faciles)

**Jour 1 - Configuration**
- Installation environnement (PZ dev mode, StarlitLibrary)
- Tests mod existant, identification bugs actuels
- Setup versioning (Git)

**Jour 2 - Visuels**
- Création/optimisation sprites 4 directions (N/S/E/W)
- Images promotionnelles (preview.png, poster.png)
- Édition `test.tiles` et `test.pack`

---

## **Jour 3 : Mécaniques Core** ⚠️
### *Phase technique critique*

**Objectifs:**
- Connexion/déconnexion piliers
- Persistance données (ModData)
- Gestion états limites

**Points techniques complexes:**

```
🔧 Problème #1: Sauvegarde État
─────────────────────────────────
Actuellement le mod ne sauvegarde pas l'état de connexion.
Si vous quittez/rechargez, les lampes "oublient" leur connexion.

Solution → Implémenter ModData système:
• Stocker ID générateur + position lampe
• Hook OnLoad/OnSave pour persistence
• Restaurer connexions au chargement carte

Fichier: lua/shared/ModData.lua (nouveau)
```

```
🔧 Problème #2: Déconnexion
───────────────────────────
Actuellement impossible de déconnecter.

Solution → Créer DisconnectLampAction:
• Détecter lampes connectées (via ModData)
• Animation inverse (unplug)
• Restaurer pilier bois original
• Retourner 1 câble électrique

Fichier: lua/client/DisconnectLampAction.lua (nouveau)
```

```
🔧 Problème #3: Destruction Objet
─────────────────────────────────
Si pilier détruit pendant qu'il est connecté = crash potentiel

Solution → Hooks destruction:
• OnObjectAboutToBeRemoved event
• Nettoyer ModData associé
• Despawn proprement IsoLightSwitch
• Éviter références mortes

Ajout: lampUtils.lua → cleanupLampData()
```

---

## **Jour 4 : Système Électrique** ⚠️⚠️
### *Phase la plus complexe du projet*

**Objectif:** Connecter réellement les lampes au système électrique de PZ

**Architecture actuelle (problème):**
```
[Pilier connecté] → Allumé 24/7
     ↓
Pas de lien réel avec générateur
Pas de consommation fuel
```

**Architecture cible:**
```
[Générateur] ──wire──> [Pilier] ──power?──> [Lumière ON/OFF]
     │
     └─> Fuel check → Si vide = Lampe OFF
```

**Défis techniques majeurs:**

```
⚡ Défi #1: API Électricité PZ
──────────────────────────────
L'API électricité de Project Zomboid est mal documentée.
Les lampes utilisent IsoLightSwitch mais il faut comprendre:
• Comment PZ gère le réseau électrique interne
• getSquare():haveElectricity() - fiable ?
• Interaction avec IsoGenerator class

Solution:
1. Reverse-engineer mods électriques existants (Electrical Overhaul)
2. Tests intensifs avec multiples générateurs
3. Fallback: polling toutes les 10 minutes (pas élégant mais stable)
```

```
⚡ Défi #2: Synchronisation Multiplayer
───────────────────────────────────────
Client/Serveur architecture de PZ nécessite:

Server-side (lua/server/):
• ElectricityManager.lua - Authority sur états électriques
• Broadcast état ON/OFF à tous les clients
• Utiliser sendServerCommand() / receiveServerCommand()

Client-side:
• Recevoir updates serveur
• Appliquer changements visuels (lumière on/off)
• Éviter désync (client pense ON, serveur dit OFF)

Protocole réseau à implémenter:
1. Client demande connexion → Serveur valide → Broadcast
2. Serveur check fuel périodiquement → Update clients
3. Gestion reconnexion joueur (sync état actuel)
```

```
⚡ Défi #3: Performance Multiple Lampes
───────────────────────────────────────
Si joueur place 50+ lampes connectées:
• Ne pas check fuel 50x par seconde
• Batching: Regrouper lampes par générateur
• Cache résultats checks
• Throttle updates visuelles (30 FPS suffit)
```

**Fichiers à créer:**
- `lua/server/ElectricityManager.lua` (200+ lignes)
- `lua/server/NetworkHandlers.lua`
- `lua/shared/Constants.lua` (UPDATE_INTERVAL, etc.)

**Temps estimé réel:** 1.5 jours (risque débordement)

---

## **Jour 5 : Polish & UX**
### Features optionnelles mais importantes

**Audio:**
- Sons connexion/déconnexion (réutiliser assets PZ)
- Buzzing optionnel pour lampes allumées

**Feedback visuel:**
- Tooltip état connexion (connecté à quel générateur ?)
- Particules si déconnexion

**Rotation post-connexion:**
- Techniquement difficile (PZ limite IsoObject rotation)
- Si impossible: documenter limitation clairement

---

## **Jour 6 : Tests & Équilibrage**
### QA intensive

**Checklist critique:**
```
[ ] 4 orientations fonctionnent
[ ] Save/Load préserve connexions
[ ] Fuel épuisé = lumière éteinte
[ ] Multiple joueurs simultanés (serveur dédié)
[ ] Destruction pilier = cleanup ModData
[ ] Déplacement générateur = lampes se déconnectent ?
[ ] 100+ lampes simultanées sans lag
```

**Équilibrage:**
- Niveau électricité requis (3 → 2 ?)
- Coût câble (1 ou 2 unités ?)
- Distance max générateur-lampe ?

---

## **Jour 7 : Compatibilité**
### Tests avec autres mods

**Mods à tester:**
- Hydrocraft (nombreux items électriques)
- Electrical Overhaul (peut conflictuer)
- More Builds (construction avancée)

**Options Sandbox:**
```lua
-- Permettre configuration serveur
SandboxVars.WiredLamp = {
    ElectricityLevel = 3,
    CableCost = 1,
    AllowDisconnect = true,
    LightRadius = 12
}
```

**Optimisations:**
- Profiling mémoire (éviter leaks)
- Réduire appels `getSquare()` (coûteux)

---

## **Jour 8 : Release**
### Publication Steam Workshop

**Checklist finale:**
```
[ ] workshop.txt mis à jour (tags, description)
[ ] Screenshots in-game (5 minimum)
[ ] README.md EN + FR
[ ] CHANGELOG.md v1.0
[ ] Test installation propre
[ ] Upload Workshop
```

**Communication:**
- Post Reddit r/projectzomboid
- Forums officiels
- Discord PZ modding

---

## 🚨 **Points de Blocage Critiques**

```
RISQUE MAJEUR                        MITIGATION
════════════════════════════════════════════════════════════
🔴 API électricité instable         → Polling fallback
🔴 Sync multiplayer complexe        → Jour 4 extensible
🟡 StarlitLibrary update breaking   → Pin version exacte
🟡 Rotation impossible (PZ engine)  → Documenter limite
```

---

## 📊 **Complexité par Jour**

```
Jour  Difficulté  Risque   Temps Réel
════════════════════════════════════════
J1    ░░░░░░░░░░  Faible   6h
J2    ░░░░░░░░░░  Faible   7h
J3    ████████░░  Moyen    10h ⚠️
J4    ██████████  ÉLEVÉ    12h+ ⚠️⚠️
J5    ███░░░░░░░  Faible   8h
J6    █████░░░░░  Moyen    9h
J7    ████░░░░░░  Moyen    8h
J8    ██░░░░░░░░  Faible   6h
```

**Prévision réaliste:** Jour 4 peut déborder sur Jour 5.
**Total:** ~66h de travail effectif (8-9h/jour)

---

**Version:** 2.0 (Simplifiée)
**Générée:** 2025-12-20
