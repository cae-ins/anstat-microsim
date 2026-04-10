# 📊 Distributive Impact of Indirect Taxes in Côte d'Ivoire
### CEQ-Based Microsimulation · EHCVM 2021 · Working Paper — April 2026

> **ANStat — Cellule d'Analyses Économiques (CAE)**  
> Armand Djaha, M.Sc. · Applied Economist | Research

---

## 🗂️ Table of Contents

- [Overview](#overview)
- [Conceptual Framework](#conceptual-framework)
- [Methodology](#methodology)
- [Data](#data)
- [Informality & Effective Taxation](#informality--effective-taxation)
- [Outputs](#outputs)
- [Key Assumptions](#key-assumptions)
- [Limitations](#limitations)
- [Repository Structure](#repository-structure)
- [Reproducibility](#reproducibility)
- [References](#references)
- [Author](#author)

---

## Overview

This project estimates the **distributional incidence of Value Added Tax (VAT)** in Côte d'Ivoire using household-level consumption data from the **EHCVM 2021 survey**.

The core objective is to identify **who effectively bears the burden of VAT** — both in absolute terms and relative to total consumption — and to assess whether the tax system is **progressive, proportional, or regressive** across the welfare distribution.

The analysis is designed as a **first-order fiscal incidence exercise**, providing a transparent and reproducible framework adapted to data-constrained environments typical of Sub-Saharan Africa.

---

## Conceptual Framework

The analysis follows a **CEQ-inspired (Commitment to Equity)** framework, adapted to the Ivorian context and available data.

In a standard CEQ setting, multiple income concepts are compared (market income, disposable income, consumable income, final income). Due to data limitations, this project focuses on the transition from **observed consumption** to a **simulated post-tax welfare measure**.

### Core Identity

```
Consumable Income = Total Consumption − Indirect Taxes (VAT)
```

This identity isolates the **direct welfare effect of consumption taxes** at the household level.

---

## Methodology

The empirical strategy relies on a **bottom-up microsimulation approach** in five steps:

| Step | Description |
|------|-------------|
| **1. Consumption Aggregation** | Household-level consumption constructed from product-level expenditures |
| **2. Tax Mapping** | Each product (`codpr`) assigned a fiscal treatment (exempt / reduced / standard rate) |
| **3. Tax Imputation** | VAT simulated at product level, then aggregated at household level |
| **4. Welfare Comparison** | Pre-tax consumption compared to simulated consumable income |
| **5. Distributional Analysis** | Results analyzed across deciles using ETRs, concentration curves, and progressivity indices |

---

## Data

| Attribute | Detail |
|-----------|--------|
| **Source** | EHCVM 2021 — Côte d'Ivoire |
| **Unit of observation** | Household × product |
| **Unit of analysis** | Household |

### Key Variables

| Variable | Description |
|----------|-------------|
| `codpr` | Product identifier |
| `modep` | Acquisition mode (market, own production, gift, etc.) |
| `depan` | Annual expenditure |
| `hhweight` | Sampling weight |

---

## Informality & Effective Taxation

A key challenge in developing economies is that **not all transactions are effectively taxed**, due to the prevalence of the informal sector.

To address this, the analysis incorporates **heterogeneous effective taxation scenarios** based on the **Informality Engel Curve (IEC)** framework (Bachas, Gadenne & Jensen, 2024).

### Scenario 1 — Strict (α = 1)
- Full taxation of all eligible consumption
- Represents a **theoretical upper bound**
- Baseline for comparison

### Scenario 2 — CEI × Location
- α varies by COICOP category **and** urban/rural location
- Captures structural differences in market access and formalization

### Scenario 3 — CEI × Decile
- α increases monotonically with consumption level
- Reflects that **wealthier households transact more in formal markets**

These scenarios allow robust testing of **how informality shapes distributional outcomes**, beyond aggregate tax levels.

---

## Outputs

The project produces the following distributional indicators:

- ✅ Effective VAT rates by decile
- ✅ Tax burden (absolute and relative to consumption)
- ✅ Concentration curves (pre- and post-tax)
- ✅ Gini coefficients (pre- and post-tax)
- ✅ **Kakwani index** of tax progressivity
- ✅ Sensitivity and robustness analysis across scenarios

---

## Key Assumptions

| Assumption | Description |
|------------|-------------|
| **Full pass-through** | VAT is fully reflected in consumer prices (no producer absorption) |
| **Consumption as welfare proxy** | Total household consumption used as proxy for permanent income |
| **Partial equilibrium** | No indirect effects via production chains or GE adjustments |

> Results should be interpreted as a **first-order approximation** of tax incidence.

---

## Limitations

- ❌ No direct taxes or social transfers modeled
- ❌ No behavioral responses (price or demand adjustments)
- ❌ No input-output transmission effects
- ❌ Informality modeled through scenarios, not directly observed

These limitations are explicitly acknowledged as part of a **transparent and progressive research strategy**.

---

## Repository Structure

```
📁 vat-incidence-civ/
│
├── 📁 data/
│   ├── raw/              # EHCVM 2021 raw files (versioned)
│   └── processed/        # Cleaned and merged datasets
│
├── 📁 code/
│   ├── 00_master.do   # master script
│   ├── 00_setup.do    # prepare environnment
│   ├── 01_prepare_data.do # Data preparation & variable construction
│   ├── 02_mapping_tax.do  # Build a clean and auditable VAT mapping  
│   ├── 03_compute_taxes.do # Compute household-level VAT incidence
│   ├── 04_analysis.do  # Produce the main CEQ-style distributive results
│   ├── 05_progressivity.do # Measure VAT progressivity
│   ├── 06_01_sensitivity_taxation.do     # Product-level fiscal treatment
│   ├── 06_02_ranking.do      # Sensitivity analysis of VAT incidence to alternative assumptions
│   ├── 07_appendix_tables.do # Produce supplementary tables
│   ├── 08_figures.do   # Produce figures 
│   └── 09_vat_determinants.do      # Analyze the socio-demographic determinants of household exposure to VAT
│
├── 📁 output/
│   ├── tables/  # Excel tables
    ├── final_data/ # final datasets
    ├── logs/  
│   └── figures/          # Concentration curves, ETR profiles
│
├── 📁 docs/
│   ├── EHCVM_products
    ├── presentation
    ├── scenario_calibration
    ├── statutory_rates
│   └── wording
│
└── README.md
```

---

## Reproducibility

The repository is structured to ensure full reproducibility:

- All code is written in **Stata** (`.do` files) with inline comments
- Random seeds are fixed where applicable
- Raw data paths are parameterized via a `globals.do` master file
- Results are automatically exported to `/output/`



---

## References

- Bachas, P., Gadenne, L., & Jensen, A. (2024). *Informality, Consumption Taxes, and Redistribution*. American Economic Review.
- Lustig, N. (Ed.) (2018). *Commitment to Equity Handbook*. Brookings Institution Press.
- World Bank (2024). *Urban Informality in Sub-Saharan Africa*. Policy Research Working Paper No. 10703.
- UNECA (2019). *Economic Report on Africa: Fiscal Policy for Financing Sustainable Development*.

---

## Author

**Armand Djaha, M.Sc.**  
Applied Economist · ANStat — Cellule d'Analyses Économiques (CAE)  
Côte d'Ivoire / Canada

[![Email](https://img.shields.io/badge/Email-armandjaha@gmail.com-blue?style=flat-square&logo=gmail)](mailto:armandjaha@gmail.com)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Armand_Djaha-0077B5?style=flat-square&logo=linkedin)](https://www.linkedin.com/in/armand-djaha-m-sc-108119186)

---

## Status

![Status](https://img.shields.io/badge/Status-Working%20Paper-orange?style=flat-square)
![Date](https://img.shields.io/badge/Date-April%202026-lightgrey?style=flat-square)
![Institution](https://img.shields.io/badge/Institution-ANStat%20CAE-green?style=flat-square)

> 📌 *Working paper — April 2026 · Final project (ANStat)*
