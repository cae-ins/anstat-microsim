# Vérification post-révision — Refine.ink

**Date :** 19 juillet 2026
**Manuscrit vérifié :** `DT_CEQ_CIV2021.tex` et `DT_CEQ_CIV2021_v17.pdf`
**Méthode :** vérification séquentielle contre le manuscrit, les classeurs, les rapports CSV et le journal LaTeX. La délégation à un sous-agent était désactivée par les règles d'exécution de cette session.

## Résultat

**Affirmations vérifiées :** 9
**PASS :** 9
**PARTIAL :** 0
**FAIL :** 0
**Conclusion :** PASS

| ID | Affirmation contrôlée | Preuve indépendante du texte de réponse | Résultat |
|---|---|---|---|
| C1 | S3 publie 150 coefficients et un profil 0,266–0,578 | feuille `matrice_S3`: 15 lignes × 10 déciles; feuille `profil_implicite_decile`: 0,2656462 et 0,5779433 | PASS |
| C2 | La sensibilité juridique donne 214,4→22,3 et 907,3→719,0 mds | `13_07_legal_deduction_sensitivity.xlsx`, scénarios `s3` et `s3_legal` | PASS |
| C3 | Le choc à 9 % est nommé taxe sur la vente finale à c constant | manuscrit, lignes 1208 et 1947; tableau 15, p. 36 | PASS |
| C4 | PSSN déclarés d'abord: 192 544, 24 989, 79,5 %, 27,108 mds | feuille `robustesse_declares_dabord` de `18_02_coverage_targeting.xlsx` | PASS |
| C5 | IRPP central/strict/élargi: 225,5/192,0/215,6 mds avec effectifs publiés | feuille `profils_scenarios` de `16_07_robustness_diagnostics.xlsx` | PASS |
| C6 | Une non-réponse n'est pas recodée comme emploi formel | `formel_fiscal_nonrep_diag = formel_fiscal_bm`; notes de scénarios; manuscrit lignes 923–930 | PASS |
| C7 | Les dénominateurs et l'hypothèse additive sont explicités | équations 8 et 16, p. 12 et p. 14; manuscrit lignes 680–693 et 824–829 | PASS |
| C8 | Les unités par personne sont homogènes | équation 7, p. 11; manuscrit lignes 635–650; identités du script `22_income_concepts.R` | PASS |
| C9 | La reproduction et la compilation réussissent | `preflight_report.csv`: 40 PASS; `verification_report.csv`: 32 PASS; PDF: 52 pages; journal LaTeX: aucune référence manquante ni boîte débordante | PASS |
