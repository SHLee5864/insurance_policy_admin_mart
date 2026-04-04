# 📌 Insurance Policy Admin Mart — Projet dbt

Ce projet dbt construit un **data mart analytique** dédié à la gestion des polices d'assurance.  
L'architecture suit une approche modulaire et scalable : **RAW → STAGING → INTERMEDIATE → MART**,  
avec un accent fort sur la qualité des données, la traçabilité et la logique métier actuarielle.

> **Partie 1 d'une série de 3 projets** construisant une plateforme de données actuarielles IFRS 17.  
> → **Medium :** [Développement des Sinistres — LDF & Sinistre Ultime](https://github.com/SHLee5864/insurance-claims-loss-development-dbt)  
> → **Large :** Plateforme IFRS 17 sur Azure *(en cours)*

---

## 🎯 Pourquoi ce projet ?

Les assureurs ont besoin d'une base analytique fiable avant de pouvoir répondre aux questions difficiles : combien allons-nous payer in fine sur les sinistres ouverts ? Nos primes sont-elles suffisantes ? À quoi ressemble notre portefeuille par produit et par segment ?

Ce projet répond à la **première couche** de ces questions : structurer le portefeuille de polices et calculer les KPI statiques (loss ratio, fréquence, sévérité) qui constituent l'entrée des workflows de provisionnement actuariel.

Dans le cadre d'IFRS 17, cela correspond à la **structure de regroupement du portefeuille et des cohortes** nécessaire avant tout calcul de BEL ou de CSM.

---

## 🛠️ Stack technique

| Composant | Technologie |
|-----------|------------|
| Transformation | dbt Core |
| Base de données | DuckDB |
| Packages | dbt-utils 1.2.0 |
| Données sources | CSV seeds (générés via `generate.py`) |

---

## 🏗️ Architecture

```
🌱 RAW (SEEDS)
   ├─ policies.csv
   ├─ premiums.csv
   ├─ claims.csv
   ├─ insureds.csv
   ├─ coverages.csv
   ├─ products.csv
   └─ policy_status_history.csv
        │
        ▼
🔵 STAGING — Normalisation & Typage
   ├─ stg_policies
   ├─ stg_premiums
   ├─ stg_claims
   ├─ stg_insureds
   ├─ stg_coverages
   ├─ stg_products
   └─ stg_policy_status_history
        │
        ▼
🟣 INTERMEDIATE — Logique métier
   ├─ int_policy_status_history
   ├─ int_policy_latest
   ├─ int_policy_premiums
   ├─ int_policy_claims
   ├─ int_policy_coverages
   └─ int_policy_portfolio
        │
        ▼
🟠 MART — KPI analytiques & Dimensions
   ├─ mrt_policy_portfolio_summary
   ├─ mrt_policy_coverage_summary
   ├─ mrt_policy_status_timeline
   ├─ dim_coverage
   └─ dim_product
```

---

## 🔹 Détail des couches

### RAW (Seeds)

Sources brutes sous forme de fichiers CSV, générés via `generate.py`.  
En production : connecteurs vers les systèmes de gestion (Guidewire, SAP FS-CD, Duck Creek).

### STAGING — Normalisation & Typage

Objectif : nettoyer, typer et standardiser les données brutes. Aucune logique métier à cette couche.

| Modèle | Grain |
|--------|-------|
| `stg_policies` | 1 ligne = 1 police |
| `stg_insureds` | 1 ligne = 1 assuré |
| `stg_premiums` | 1 ligne = 1 prime |
| `stg_claims` | 1 ligne = 1 sinistre |
| `stg_coverages` | 1 ligne = 1 garantie |
| `stg_products` | 1 ligne = 1 produit |
| `stg_policy_status_history` | 1 ligne = 1 changement de statut |

Actions réalisées : cast des dates, harmonisation des statuts, suppression des doublons, validation des clés primaires.

### INTERMEDIATE — Logique métier

| Modèle | Rôle | Grain | Décision de conception |
|--------|------|-------|----------------------|
| `int_policy_status_history` | Historique complet des statuts | 1 ligne = 1 période de statut (start → end) | `lead()` pour calculer `end_date` absent dans la source |
| `int_policy_latest` | Statut courant par police | 1 ligne = 1 police | Référence directe à `stg_policy_status_history` — indépendant de `int_policy_status_history` pour minimiser les dépendances |
| `int_policy_premiums` | Primes des contrats actifs | 1 ligne = 1 prime active | Filtré sur `policy_status = 'active'` — périmètre actuariel intentionnel |
| `int_policy_claims` | Sinistres des contrats actifs | 1 ligne = 1 sinistre actif | Même périmètre que `int_policy_premiums` |
| `int_policy_coverages` | Garanties par police | 1 ligne = 1 garantie par police | — |
| `int_policy_portfolio` | Jointure police–assuré + segmentation | 1 ligne = 1 police (vue enrichie) | Attributs statiques uniquement |

### MART — KPI analytiques & Dimensions

| Modèle | Contenu | Grain |
|--------|---------|-------|
| `mrt_policy_portfolio_summary` | Loss ratio, fréquence, sévérité par produit/segment | 1 ligne = 1 segment / produit / période |
| `mrt_policy_coverage_summary` | Analyse des garanties par type | 1 ligne = 1 type de garantie / période |
| `mrt_policy_status_timeline` | Suivi des transitions de statut | 1 ligne = 1 transition de statut |
| `dim_coverage` | Dimension des garanties | 1 ligne = 1 garantie |
| `dim_product` | Dimension des produits | 1 ligne = 1 produit |

---

## 📊 KPI disponibles

| KPI | Formule | Modèle source |
|-----|---------|---------------|
| Loss Ratio | Total sinistres / Total primes | `mrt_policy_portfolio_summary` |
| Fréquence | Nb sinistres / Nb polices | `mrt_policy_portfolio_summary` |
| Sévérité | Montant moyen par sinistre | `mrt_policy_portfolio_summary` |
| Couverture | Nb garanties par police | `mrt_policy_coverage_summary` |

---

## 🔗 Lien avec IFRS 17

Ce projet pose les fondations analytiques nécessaires aux workflows IFRS 17 :

| Ce projet | Pertinence IFRS 17 |
|---|---|
| `mrt_policy_portfolio_summary` | Regroupement du portefeuille et primes acquises par cohorte (§17) |
| `mrt_policy_status_timeline` | Test des limites contractuelles — suivi des entrées/sorties de périmètre |
| Loss Ratio par produit/AY | Entrée pour le calibrage de la Meilleure Estimation (BEL) |
| Structure des garanties | Base pour l'identification des unités de couverture (amortissement du CSM) |

Le **projet Medium** prolonge ces fondations vers les triangles de développement des sinistres, le calcul des LDF et l'estimation du sinistre ultime — les entrées fondamentales du BEL sinistres (IFRS 17 §40–42).

---

## 🧪 Qualité des données

### Tests automatiques dbt

- `unique` sur les clés primaires
- `not_null` sur les champs critiques
- `accepted_values` sur les statuts
- `relationships` entre les couches

### Tests personnalisés (macros)

- `expiry_date_after_effective_date`
- `updated_at_after_effective_date`

### Documentation YAML

Chaque modèle est documenté avec : description, grain, colonnes + tests, dépendances.

---

## 🧱 Simplifications vs. production réelle

| Ce projet | Réalité en production |
|---|---|
| Fichiers CSV seeds | Systèmes de gestion de polices (Guidewire, SAP FS-CD) |
| `updated_at` typé en `date` | `timestamp` pour la traçabilité intra-journalière |
| Transitions active/cancelled uniquement | Cycle complet : suspended, reinstated, expired, lapsed |
| Loss ratio statique | Les estimations actuariellement crédibles nécessitent des triangles de développement → voir projet Medium |
| Pas de BEL par cohorte | IFRS 17 exige un regroupement par année d'émission, rentabilité et produit |

---

## 🗃️ Génération des données

Les données seed sont générées via `generate.py` :

- ~30–50 polices actives par mois sur la période 2023–2025
- Primes mensuelles pour chaque police active
- Sinistres calibrés pour un **loss ratio réaliste de 85–105%** par produit/année
- 10 produits d'assurance (vie, accident, santé, cancer, invalidité)
- Historique de statuts avec transitions active → cancelled
- Garanties multiples par police selon le produit

---

## ⚙️ Exécution

```bash
# Installer les dépendances dbt
dbt deps

# Charger les seeds + exécuter les modèles + lancer les tests
dbt build

# Ou étape par étape :
dbt seed     # Charger les CSV
dbt run      # Exécuter les modèles
dbt test     # Lancer les tests
```

`profiles.yml` (`~/.dbt/profiles.yml`) :

```yaml
insurance_policy_admin_mart:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: dev.duckdb
      threads: 4
```

---

## 👤 Auteur

**Sukhee Lee** — Actuarial Data Analyst | IFRS 17 · dbt · Databricks  
Alliance entre expertise actuarielle et pratiques modernes d'ingénierie des données  
pour construire des pipelines analytiques reproductibles et auditables dédiés au provisionnement assurance.
