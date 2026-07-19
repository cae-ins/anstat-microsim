# 24_fiscal_impoverishment.R
# Mesure les ménages dont les ressources monétaires sous le seuil diminuent ou
# augmentent après impôts, cotisations, paiements publics et réductions de prix.

fiscal_impoverishment <- function(paths) {
  message(">>> ETAPE 25 : Appauvrissement fiscal et gains sous le seuil")
  input <- file.path(paths$SILVER, "22", "all_income_concepts.parquet")
  assert_local_file_exists(input); hh <- load_parquet(input)
  required <- c("hhid", "grappe", "strata", "hhweight", "pcweight", "decile",
    "hhsize", "zref", "yp_pc_pdi", "yp_pc_pgt", "yc_pc", "yd_pc",
    "subsidy_total_hh_real")
  assert_required_columns(hh, required, "concepts de revenu")

  measure <- function(pre, post, z, w) {
    loss <- pmax(pmin(pre, z) - pmin(post, z), 0)
    gain <- pmax(pmin(post, z) - pmin(pre, z), 0)
    tibble::tibble(
      part_population_appauvrie = stats::weighted.mean(post < pre & post < z, w),
      part_nouveaux_pauvres = stats::weighted.mean(pre >= z & post < z, w),
      part_population_gagnante_sous_seuil = stats::weighted.mean(post > pre & pre < z, w),
      perte_moyenne_population = stats::weighted.mean(loss, w),
      gain_moyen_population = stats::weighted.mean(gain, w),
      perte_nationale_milliards = sum(loss * w) / 1e9,
      gain_national_milliards = sum(gain * w) / 1e9,
      fgt0_avant = fgt_index(pre, z, w, 0), fgt0_apres = fgt_index(post, z, w, 0),
      fgt1_avant = fgt_index(pre, z, w, 1), fgt1_apres = fgt_index(post, z, w, 1),
      ecart_fgt1 = fgt_index(post, z, w, 1) - fgt_index(pre, z, w, 1),
      ecart_fgt1_reconstruit = stats::weighted.mean((loss - gain) / z, w))
  }

  hh <- hh |>
    dplyr::mutate(
      fiscal_loss_pdi = pmax(pmin(yp_pc_pdi, zref) - pmin(yc_pc, zref), 0),
      fiscal_gain_pdi = pmax(pmin(yc_pc, zref) - pmin(yp_pc_pdi, zref), 0),
      fiscal_impoverished_pdi = yc_pc < yp_pc_pdi & yc_pc < zref,
      fiscal_new_poor_pdi = yp_pc_pdi >= zref & yc_pc < zref,
      fiscal_gainer_pdi = yc_pc > yp_pc_pdi & yp_pc_pdi < zref,
      fiscal_loss_pgt = pmax(pmin(yp_pc_pgt, zref) - pmin(yc_pc, zref), 0),
      fiscal_gain_pgt = pmax(pmin(yc_pc, zref) - pmin(yp_pc_pgt, zref), 0))
  save_parquet(hh |> dplyr::select(hhid, grappe, strata, hhweight, pcweight,
    decile, zref, yp_pc_pdi, yp_pc_pgt, yc_pc, dplyr::starts_with("fiscal_")),
    file.path(paths$SILVER, "24", "fiscal_impoverishment.parquet"))

  central <- measure(hh$yp_pc_pdi, hh$yc_pc, hh$zref, hh$pcweight) |>
    dplyr::mutate(scenario = "PDI, système monétaire complet", .before = 1)
  pgt <- measure(hh$yp_pc_pgt, hh$yc_pc, hh$zref, hh$pcweight) |>
    dplyr::mutate(scenario = "PGT, système monétaire complet", .before = 1)
  direct_only <- measure(hh$yp_pc_pdi, hh$yd_pc, hh$zref, hh$pcweight) |>
    dplyr::mutate(scenario = "PDI, impôts et paiements directs seulement", .before = 1)
  no_indirect_tax <- measure(hh$yp_pc_pdi,
    hh$yd_pc + hh$subsidy_total_hh_real / hh$hhsize, hh$zref, hh$pcweight) |>
    dplyr::mutate(scenario = "PDI, sans impôts indirects", .before = 1)
  summary_table <- dplyr::bind_rows(central, pgt, direct_only, no_indirect_tax)
  if (max(abs(summary_table$ecart_fgt1 - summary_table$ecart_fgt1_reconstruit)) > 1e-10) {
    stop("La variation de profondeur de pauvreté ne se réconcilie pas.")
  }

  profile <- hh |>
    dplyr::mutate(statut_initial = dplyr::case_when(
      yp_pc_pdi < zref ~ "Pauvre avant intervention", TRUE ~ "Non pauvre avant intervention")) |>
    dplyr::group_by(decile, statut_initial) |>
    dplyr::summarise(
      population = sum(pcweight),
      part_appauvrie_pct = 100 * stats::weighted.mean(fiscal_impoverished_pdi, pcweight),
      part_gagnante_pct = 100 * stats::weighted.mean(fiscal_gainer_pdi, pcweight),
      perte_milliards = sum(fiscal_loss_pdi * pcweight) / 1e9,
      gain_milliards = sum(fiscal_gain_pdi * pcweight) / 1e9, .groups = "drop")

  factors <- seq(0.5, 2, by = 0.1)
  dominance <- purrr::map_dfr(factors, function(f) {
    z <- hh$zref * f
    m <- measure(hh$yp_pc_pdi, hh$yc_pc, z, hh$pcweight)
    dplyr::mutate(m, facteur_seuil = f, .before = 1)
  })

  reps <- 500L; seed <- 20240925L; set.seed(seed)
  boot <- matrix(NA_real_, nrow = reps, ncol = 4,
                 dimnames = list(NULL, c("part_appauvrie", "part_nouveaux_pauvres",
                                        "perte_milliards", "gain_milliards")))
  for (b in seq_len(reps)) {
    w <- rao_wu_weights(hh, "pcweight", "grappe", "strata")
    m <- measure(hh$yp_pc_pdi, hh$yc_pc, hh$zref, w)
    boot[b, ] <- c(m$part_population_appauvrie, m$part_nouveaux_pauvres,
                   m$perte_nationale_milliards, m$gain_national_milliards)
  }
  bootstrap <- purrr::map_dfr(seq_len(ncol(boot)), function(i) {
    x <- boot[, i]
    tibble::tibble(indicateur = colnames(boot)[[i]],
      estimation = c(central$part_population_appauvrie,
        central$part_nouveaux_pauvres, central$perte_nationale_milliards,
        central$gain_national_milliards)[[i]],
      ic95_bas = unname(stats::quantile(x, 0.025)),
      ic95_haut = unname(stats::quantile(x, 0.975)),
      ecart_type = stats::sd(x), repetitions_valides = sum(is.finite(x)),
      methode = "Bootstrap Rao-Wu, grappes et strates EHCVM")
  })
  reconciliation <- summary_table |>
    dplyr::select(scenario, fgt1_avant, fgt1_apres, ecart_fgt1,
                  ecart_fgt1_reconstruit) |>
    dplyr::mutate(ecart_numerique = ecart_fgt1 - ecart_fgt1_reconstruit)

  export_excel(summary_table, file.path(paths$TABLES, "24", "24_01_fiscal_impoverishment.xlsx"))
  export_excel(profile, file.path(paths$TABLES, "24", "24_02_profiles.xlsx"))
  export_excel(dominance, file.path(paths$TABLES, "24", "24_03_threshold_dominance.xlsx"))
  export_excel(bootstrap, file.path(paths$TABLES, "24", "24_04_inference.xlsx"))
  export_excel(reconciliation, file.path(paths$TABLES, "24", "24_05_reconciliation.xlsx"))

  fig_data <- dominance |>
    dplyr::select(facteur_seuil, perte_nationale_milliards, gain_national_milliards) |>
    tidyr::pivot_longer(-facteur_seuil, names_to = "mesure", values_to = "milliards") |>
    dplyr::mutate(mesure = dplyr::recode(mesure,
      perte_nationale_milliards = "Appauvrissement fiscal",
      gain_national_milliards = "Gains sous le seuil"))
  fig <- ggplot2::ggplot(fig_data, ggplot2::aes(facteur_seuil, milliards, color = mesure)) +
    ggplot2::geom_line(linewidth = 1) + ggplot2::scale_color_manual(values = c(
      "Appauvrissement fiscal"="#FF7F0E", "Gains sous le seuil"="#2CA02C")) +
    ggplot2::labs(title = "Pertes et gains monétaires sous différents seuils",
      subtitle = "Le seuil national 2021 correspond au facteur 1",
      x = "Multiple du seuil national", y = "Milliards de FCFA", color = NULL) +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(legend.position = "bottom")
  export_fig(fig, file.path(paths$FIGS, "fig24_fiscal_impoverishment.png"), width = 9.5, height = 6)

  message(sprintf("  Population appauvrie : %.2f %% ; nouveaux pauvres : %.2f %%",
    100 * central$part_population_appauvrie, 100 * central$part_nouveaux_pauvres))
  invisible(summary_table)
}