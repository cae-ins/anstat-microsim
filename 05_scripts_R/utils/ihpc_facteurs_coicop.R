# Facteurs de revalorisation 2021 -> 2025 par fonction COICOP, a partir de
# l'IHPC de l'ANStat (bulletins mensuels). Hors pipeline : ce script lit un
# fichier de reference transcrit a la main et ecrit un tableau de facteurs.
#
# Methode :
#  - moyenne annuelle 2021 par fonction en base 2014 (12 bulletins mensuels,
#    couverts par les bulletins de mars, juin, septembre et decembre 2021) ;
#  - moyenne annuelle 2023 par fonction en base 2014 (memes bulletins de 2023) ;
#  - moyenne annuelle 2025 par fonction en base 2023 (bulletins d'avril,
#    juillet, septembre et decembre 2025, plus janvier 2025) ;
#  - raccord : l'ANStat raccorde l'ancienne serie a la base 2023 par le ratio
#    100 / moyenne 2023 (base 2014) de chaque fonction. Ce raccord est verifie
#    ici sur janvier 2024, publie dans les deux bases ;
#  - facteur 2021 -> 2025 = moyenne 2025 (base 2023) / [moyenne 2021 (base 2014)
#    x 100 / moyenne 2023 (base 2014)].
#  - la division 12 de l'ancienne nomenclature (Biens et services divers)
#    correspond aux divisions 12 et 13 de la COICOP 2018 ; le raccord suit la
#    division 13 (Protection sociale et soins personnels), comme le fait
#    l'ANStat dans ses series raccordees.
#
# Execution depuis la racine du depot :
#   Rscript --vanilla 05_scripts_R/utils/ihpc_facteurs_coicop.R

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

src <- file.path("01_data_sources", "reference_external",
                 "ANSTAT_IHPC_fonctions_mensuel.csv")
out <- file.path("01_data_sources", "reference_external",
                 "ANSTAT_IHPC_facteurs_2021_2025.csv")

ihpc <- read_csv(src, col_types = cols(code = col_character(),
                                       .default = col_guess()))

# Moyennes annuelles par base, annee et fonction (12 mois exiges)
moyennes <- ihpc |>
  filter(annee %in% c(2021, 2023, 2025)) |>
  group_by(base, annee, code) |>
  summarise(n_mois = n(), moyenne = mean(indice), .groups = "drop")

stopifnot(all(moyennes$n_mois == 12))

m21 <- moyennes |> filter(base == 2014, annee == 2021) |>
  select(code, moy_2021_b2014 = moyenne)
m23 <- moyennes |> filter(base == 2014, annee == 2023) |>
  select(code, moy_2023_b2014 = moyenne)
m25 <- moyennes |> filter(base == 2023, annee == 2025) |>
  select(code, moy_2025_b2023 = moyenne)

# Correspondance ancienne division 12 -> nouvelles divisions 12 et 13
m25 <- m25 |>
  mutate(code_ancien = if_else(code %in% c("12", "13"), "12", code))

# Verification du raccord sur janvier 2024 (publie dans les deux bases)
j24_old <- ihpc |> filter(base == 2014, annee == 2024, mois == 1) |>
  select(code, janv24_b2014 = indice)
j24_new <- ihpc |> filter(base == 2023, annee == 2024, mois == 1) |>
  mutate(code_ancien = if_else(code == "13", "12", code)) |>
  select(code_ancien, janv24_b2023 = indice)

raccord <- m23 |>
  left_join(j24_old, by = "code") |>
  left_join(j24_new, by = c("code" = "code_ancien")) |>
  mutate(
    coefficient_raccord = 100 / moy_2023_b2014,
    janv24_raccorde     = janv24_b2014 * coefficient_raccord,
    ecart_janv24        = janv24_raccorde - janv24_b2023
  )

facteurs <- m25 |>
  left_join(m21, by = c("code_ancien" = "code")) |>
  left_join(m23, by = c("code_ancien" = "code")) |>
  mutate(
    moy_2021_raccordee = moy_2021_b2014 * 100 / moy_2023_b2014,
    facteur_2021_2025  = moy_2025_b2023 / moy_2021_raccordee,
    hausse_pct         = 100 * (facteur_2021_2025 - 1)
  ) |>
  left_join(ihpc |> filter(base == 2023, annee == 2025, mois == 12) |>
              select(code, libelle), by = "code") |>
  select(code, libelle, code_ancien, moy_2021_b2014, moy_2023_b2014,
         moy_2021_raccordee, moy_2025_b2023, facteur_2021_2025, hausse_pct) |>
  arrange(code)

cat("\nVerification du raccord (janvier 2024, ecart raccorde - publie) :\n")
print(as.data.frame(raccord |>
  select(code, moy_2023_b2014, coefficient_raccord, janv24_b2014,
         janv24_raccorde, janv24_b2023, ecart_janv24)), digits = 4)

cat("\nFacteurs de revalorisation 2021 -> 2025 par fonction COICOP :\n")
print(as.data.frame(facteurs), digits = 4)

write_csv(facteurs, out)
cat("\n-> ecrit :", out, "\n")
