# 23_marginal_contribution.R
# Mesure la contribution de chaque famille d'instruments à la variation du Gini.
# La décomposition de Shapley moyenne tous les ordres possibles d'introduction.

marginal_contribution <- function(paths) {
  message(">>> ETAPE 24 : Contribution distributive des instruments")
  input <- file.path(paths$SILVER, "22", "all_income_concepts.parquet")
  assert_local_file_exists(input)
  hh <- load_parquet(input)
  required <- c("hhid", "grappe", "strata", "hhweight", "pcweight", "hhsize",
    "decile", "yp_pc_pdi", "yp_pc_pgt", "yf_pc", "direct_levies_pdi_hh_real",
    "direct_levies_pgt_hh_real", "public_transfers_hh_real",
    "public_transfers_pgt_hh_real", "indirect_taxes_hh_real",
    "subsidy_total_hh_real", "education_net_hh_real", "health_net_hh_real")
  assert_required_columns(hh, required, "concepts de revenu")

  labels <- c(
    direct_levies = "Prélèvements directs",
    direct_transfers = "Paiements publics directs",
    indirect_taxes = "Impôts indirects",
    price_reductions = "Réductions de prix",
    education = "Éducation publique",
    health = "Santé publique")

  make_effects <- function(d, convention = "pdi") {
    if (convention == "pdi") {
      direct_levy <- d$direct_levies_pdi_hh_real
      direct_transfer <- d$public_transfers_hh_real
      base <- d$yp_pc_pdi
    } else {
      direct_levy <- d$direct_levies_pgt_hh_real
      direct_transfer <- d$public_transfers_pgt_hh_real
      base <- d$yp_pc_pgt
    }
    effects <- cbind(
      direct_levies = -direct_levy / d$hhsize,
      direct_transfers = direct_transfer / d$hhsize,
      indirect_taxes = -d$indirect_taxes_hh_real / d$hhsize,
      price_reductions = d$subsidy_total_hh_real / d$hhsize,
      education = d$education_net_hh_real / d$hhsize,
      health = d$health_net_hh_real / d$hhsize)
    list(base = base, effects = effects)
  }

  shapley_core <- function(d, convention = "pdi") {
    obj <- make_effects(d, convention); base <- obj$base; effects <- obj$effects
    w <- d$pcweight; k <- ncol(effects); masks <- 0:(2^k - 1)
    g0 <- weighted_gini(pmax(base, 0), w)
    values <- numeric(length(masks))
    for (idx in seq_along(masks)) {
      mask <- masks[[idx]]
      included <- which(vapply(0:(k - 1), function(j) bitwAnd(mask, bitwShiftL(1L, j)) > 0,
                               logical(1)))
      income <- base
      if (length(included)) income <- income + rowSums(effects[, included, drop = FALSE])
      values[[idx]] <- g0 - weighted_gini(pmax(income, 0), w)
    }
    phi <- setNames(numeric(k), colnames(effects))
    for (i in seq_len(k)) {
      bit <- bitwShiftL(1L, i - 1L)
      masks_without <- masks[bitwAnd(masks, bit) == 0]
      for (mask in masks_without) {
        s <- sum(vapply(0:(k - 1), function(j) bitwAnd(mask, bitwShiftL(1L, j)) > 0,
                        logical(1)))
        weight <- factorial(s) * factorial(k - s - 1) / factorial(k)
        phi[[i]] <- phi[[i]] + weight * (values[[mask + bit + 1L]] - values[[mask + 1L]])
      }
    }
    attr(phi, "total") <- values[[length(values)]]
    attr(phi, "gini_base") <- g0
    attr(phi, "gini_final") <- g0 - values[[length(values)]]
    phi
  }

  point_table <- function(convention) {
    phi <- shapley_core(hh, convention)
    tibble::tibble(
      convention = toupper(convention), instrument = names(phi),
      libelle = unname(labels[names(phi)]), contribution_gini = as.numeric(phi),
      part_variation_totale_pct = if (abs(attr(phi, "total")) > 1e-12) {
        100 * as.numeric(phi) / attr(phi, "total")
      } else {
        rep(NA_real_, length(phi))
      },
      gini_initial = attr(phi, "gini_base"), gini_final = attr(phi, "gini_final"),
      variation_totale = attr(phi, "total"))
  }
  shapley_pdi <- point_table("pdi")
  shapley_pgt <- point_table("pgt")

  obj <- make_effects(hh, "pdi")
  final_income <- obj$base + rowSums(obj$effects)
  if (max(abs(final_income - hh$yf_pc)) > 1e-5) stop("La somme des instruments ne retrouve pas le revenu final.")
  g_base <- weighted_gini(pmax(obj$base, 0), hh$pcweight)
  g_final <- weighted_gini(pmax(final_income, 0), hh$pcweight)
  marginal <- purrr::map_dfr(seq_along(labels), function(i) {
    without <- final_income - obj$effects[, i]
    only <- obj$base + obj$effects[, i]
    tibble::tibble(
      instrument = names(labels)[[i]], libelle = labels[[i]],
      gini_sans_instrument = weighted_gini(pmax(without, 0), hh$pcweight),
      contribution_marginale = weighted_gini(pmax(without, 0), hh$pcweight) - g_final,
      variation_si_seul = g_base - weighted_gini(pmax(only, 0), hh$pcweight))
  })

  progressivity <- purrr::map_dfr(seq_along(labels), function(i) {
    amount <- abs(obj$effects[, i])
    ci <- weighted_conindex(amount, obj$base, hh$pcweight)
    type <- if (names(labels)[[i]] %in% c("direct_levies", "indirect_taxes")) "prélèvement" else "bénéfice"
    tibble::tibble(instrument = names(labels)[[i]], libelle = labels[[i]], type = type,
      coefficient_concentration = ci,
      indice = if (type == "prélèvement") ci - g_base else g_base - ci,
      lecture = if (type == "prélèvement") "positif : prélèvement progressif" else "positif : bénéfice orienté vers les ménages modestes")
  })

  reps <- 50L; seed <- 20240924L; set.seed(seed)
  boot <- matrix(NA_real_, nrow = reps, ncol = length(labels), dimnames = list(NULL, names(labels)))
  for (b in seq_len(reps)) {
    d <- hh
    d$pcweight <- rao_wu_weights(hh, "pcweight", "grappe", "strata")
    boot[b, ] <- tryCatch(as.numeric(shapley_core(d, "pdi")), error = function(e) rep(NA_real_, length(labels)))
  }
  bootstrap <- purrr::map_dfr(seq_along(labels), function(i) {
    x <- boot[, i]; x <- x[is.finite(x)]
    tibble::tibble(instrument = names(labels)[[i]], libelle = labels[[i]],
      estimation = shapley_pdi$contribution_gini[[i]],
      ic95_bas = unname(stats::quantile(x, 0.025)),
      ic95_haut = unname(stats::quantile(x, 0.975)),
      ecart_type = stats::sd(x), repetitions_valides = length(x),
      methode = "Bootstrap Rao-Wu; Shapley exacte à chaque réplication")
  })

  save_parquet(shapley_pdi, file.path(paths$SILVER, "23", "marginal_contributions.parquet"))
  export_excel(shapley_pdi, file.path(paths$TABLES, "23", "23_01_shapley_pdi.xlsx"))
  export_excel(shapley_pgt, file.path(paths$TABLES, "23", "23_02_shapley_pgt.xlsx"))
  export_excel(marginal, file.path(paths$TABLES, "23", "23_03_marginal_contributions.xlsx"))
  export_excel(progressivity, file.path(paths$TABLES, "23", "23_04_progressivity_targeting.xlsx"))
  export_excel(bootstrap, file.path(paths$TABLES, "23", "23_05_shapley_inference.xlsx"))

  fig_data <- shapley_pdi |>
    dplyr::mutate(sens = dplyr::if_else(contribution_gini >= 0,
      "Réduit l'inégalité", "Accroît l'inégalité"),
      libelle = factor(libelle, levels = rev(libelle)))
  fig <- ggplot2::ggplot(fig_data, ggplot2::aes(contribution_gini, libelle, fill = sens)) +
    ggplot2::geom_col(width = 0.7) + ggplot2::geom_vline(xintercept = 0, color = "#4D4D4D") +
    ggplot2::scale_fill_manual(values = c("Réduit l'inégalité"="#2CA02C",
                                         "Accroît l'inégalité"="#FF7F0E")) +
    ggplot2::labs(title = "Contribution de chaque instrument à la variation du Gini",
      subtitle = "Décomposition de Shapley, convention pensions comme revenu différé",
      x = "Réduction du Gini (valeur positive)", y = NULL, fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) + ggplot2::theme(legend.position = "bottom")
  export_fig(fig, file.path(paths$FIGS, "fig23_shapley.png"), width = 9, height = 6)
  message(sprintf("  Gini initial %.4f; final %.4f; réduction %.4f", g_base, g_final, g_base - g_final))
  invisible(shapley_pdi)
}