# frelon-asiatique-suisse
Analyse du frelon asiatique (Vespa velutina) en Suisse
[![R](https://img.shields.io/badge/R-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![sf](https://img.shields.io/badge/sf-spatial%20data-6A1B9A)](https://r-spatial.github.io/sf/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Ce projet analyse la répartition spatiale et temporelle du frelon asiatique (*Vespa velutina*) en Suisse à partir de données GBIF.

Il comprend :
- une analyse temporelle des observations
- une cartographie statique des signalements
- une carte interactive par canton (année 2025)

---

## Données

- **Observations** : GBIF (fichier `GBIF_VESPA_CH.csv`)
- **Limites administratives** : swisstopo – swissBOUNDARIES3D (cantons suisses)

Les données spatiales sont reprojetées en **EPSG:2056 (CH1903+)**.

---

## Outils utilisés

- R (≥ 4.2)
- RMarkdown
- Packages principaux :
  - `sf`
  - `dplyr`
  - `ggplot2`
  - `plotly`
  - `viridisLite`
  - `tidyverse`

---

## Résultats principaux

- Première observation en Suisse : **2017 (Jura)**
- Forte augmentation des signalements depuis **2022**
- En 2025, les observations sont concentrées dans certains cantons de l’ouest de la Suisse

---

## Reproduction de l’analyse

1. Cloner le dépôt :
```bash
git clone https://github.com/Trematod/frelon-asiatique-suisse.git
