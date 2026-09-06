# 23_marginal_contribution.R
# Mesure la contribution de chaque famille d'instruments à la variation du Gini
# et à celle de la pauvreté. La décomposition de Shapley moyenne tous les ordres
# possibles d'introduction. Trois lectures complémentaires accompagnent la
# décomposition : le reclassement des ménages (Atkinson-Plotnick), les
# indicateurs d'efficacité du CEQ Handbook et les intervalles de sondage.
#
# CONVENTIONS :
#   - Le Gini est calculé sur les revenus plancher à zéro, comme partout dans la
#     chaîne. Les indices FGT utilisent le revenu tel quel et le seuil ménage
#     zref, exactement comme l'étape 25.
#   - Une contribution positive réduit l'indice : elle réduit l'inégalité pour le
#     Gini, elle réduit la pauvreté pour les FGT.

marginal_contribution <- function(paths) {
  message(">>> ETAPE 24 : Contribution distributive des instruments")
  input <- file.path(paths$SILVER, "22", "all_income_concepts.parquet")
  assert_local_file_exists(input)
  hh <- load_parquet(input)
  required <- c("hhid", "grappe", "strata", "hhweight", "pcweight", "hhsize",
    "decile", "zref", "yp_pc_pdi", "yp_pc_pgt", "yd_pc", "yc_pc", "yf_pc",
    "direct_levies_pdi_hh_real",
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

  # L'indice à décomposer est passé en argument. La mécanique des 64
  # sous-ensembles et des 720 ordres reste strictement identique : seule la
  # mesure appliquée au revenu change. Le Gini reste la valeur par défaut, de
  # sorte que les sorties historiques de l'étape sont inchangées.
  gini_index <- function(income, w, d) weighted_gini(pmax(income, 0), w)
  poverty_index <- function(alpha) {
    force(alpha)
    function(income, w, d) fgt_index(income, d$zref, w, alpha)
  }

  shapley_core <- function(d, convention = "pdi", index_fn = gini_index) {
    obj <- make_effects(d, convention); base <- obj$base; effects <- obj$effects
    w <- d$pcweight; k <- ncol(effects); masks <- 0:(2^k - 1)
    g0 <- index_fn(base, w, d)
    values <- numeric(length(masks))
    for (idx in seq_along(masks)) {
      mask <- masks[[idx]]
      included <- which(vapply(0:(k - 1), function(j) bitwAnd(mask, bitwShiftL(1L, j)) > 0,
                               logical(1)))
      income <- base
      if (length(included)) income <- income + rowSums(effects[, included, drop = FALSE])
      values[[idx]] <- g0 - index_fn(income, w, d)
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
    attr(phi, "index_base") <- g0
    attr(phi, "index_final") <- g0 - values[[length(values)]]
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
      gini_initial = attr(phi, "index_base"), gini_final = attr(phi, "index_final"),
      variation_totale = attr(phi, "total"))
  }
  shapley_pdi <- point_table("pdi")
  shapley_pgt <- point_table("pgt")

  # ── Décomposition de Shapley de la pauvreté ────────────────────────────────
  # Le message central du papier porte autant sur la pauvreté que sur
  # l'inégalité. La même décomposition est donc rejouée sur l'incidence (FGT0)
  # et sur la profondeur (FGT1) de la pauvreté monétaire.
  poverty_point_table <- function(convention, alpha) {
    phi <- shapley_core(hh, convention, poverty_index(alpha))
    total <- attr(phi, "total")
    tibble::tibble(
      convention = toupper(convention),
      indice = if (alpha == 0) "FGT0 : incidence" else "FGT1 : profondeur",
      instrument = names(phi), libelle = unname(labels[names(phi)]),
      contribution_pauvrete = as.numeric(phi),
      part_variation_totale_pct = if (abs(total) > 1e-12) {
        100 * as.numeric(phi) / total
      } else {
        rep(NA_real_, length(phi))
      },
      indice_initial = attr(phi, "index_base"),
      indice_final = attr(phi, "index_final"),
      variation_totale = total)
  }
  shapley_p0 <- dplyr::bind_rows(poverty_point_table("pdi", 0),
                                 poverty_point_table("pgt", 0))
  shapley_p1 <- dplyr::bind_rows(poverty_point_table("pdi", 1),
                                 poverty_point_table("pgt", 1))
  poverty_reconciliation <- dplyr::bind_rows(shapley_p0, shapley_p1) |>
    dplyr::group_by(convention, indice) |>
    dplyr::summarise(somme_contributions = sum(contribution_pauvrete),
                     variation_totale = dplyr::first(variation_totale),
                     .groups = "drop") |>
    dplyr::mutate(ecart = somme_contributions - variation_totale)
  if (max(abs(poverty_reconciliation$ecart)) > 1e-10) {
    stop("La décomposition de Shapley de la pauvreté ne se réconcilie pas.")
  }

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

  # ── Équité verticale et reclassement ───────────────────────────────────────
  # Une intervention peut réduire l'inégalité globale tout en déplaçant les
  # ménages les uns par rapport aux autres. La décomposition d'Atkinson (1980) et
  # Plotnick (1981) sépare ces deux effets : RS = équité verticale − reclassement.
  transitions <- tibble::tribble(
    ~etape, ~avant, ~apres,
    "Revenu primaire vers revenu disponible", "yp_pc_pdi", "yd_pc",
    "Revenu disponible vers revenu consommable", "yd_pc", "yc_pc",
    "Revenu consommable vers revenu final", "yc_pc", "yf_pc",
    "Revenu primaire vers revenu final", "yp_pc_pdi", "yf_pc")
  reranking_steps <- purrr::pmap_dfr(transitions, function(etape, avant, apres) {
    d <- reranking_decomposition(hh[[avant]], hh[[apres]], hh$pcweight)
    tibble::tibble(perimetre = "Cascade des concepts", element = etape,
      gini_avant = d$gini_avant, gini_apres = d$gini_apres,
      reynolds_smolensky = d$reynolds_smolensky,
      equite_verticale = d$equite_verticale, reclassement = d$reclassement,
      # Le rapport n'a de sens que si l'effet vertical est égalisateur. Les
      # réductions de prix ont un effet vertical négatif : le rapport est alors
      # laissé vide plutôt que d'être publié avec un signe trompeur.
      part_reclassement_pct = if (d$equite_verticale > 1e-12) {
        100 * d$reclassement / d$equite_verticale
      } else NA_real_)
  })
  reranking_instruments <- purrr::map_dfr(seq_along(labels), function(i) {
    apres <- obj$base + obj$effects[, i]
    d <- reranking_decomposition(obj$base, apres, hh$pcweight)
    tibble::tibble(perimetre = "Instrument seul", element = unname(labels[[i]]),
      gini_avant = d$gini_avant, gini_apres = d$gini_apres,
      reynolds_smolensky = d$reynolds_smolensky,
      equite_verticale = d$equite_verticale, reclassement = d$reclassement,
      # Le rapport n'a de sens que si l'effet vertical est égalisateur. Les
      # réductions de prix ont un effet vertical négatif : le rapport est alors
      # laissé vide plutôt que d'être publié avec un signe trompeur.
      part_reclassement_pct = if (d$equite_verticale > 1e-12) {
        100 * d$reclassement / d$equite_verticale
      } else NA_real_)
  })
  reranking <- dplyr::bind_rows(reranking_steps, reranking_instruments)
  if (any(reranking$reclassement < -1e-10)) {
    stop("Le terme de reclassement doit être positif ou nul.")
  }
  if (max(abs(reranking$reynolds_smolensky -
              (reranking$equite_verticale - reranking$reclassement))) > 1e-10) {
    stop("La décomposition équité verticale moins reclassement ne se réconcilie pas.")
  }

  # ── Indicateurs d'efficacité ───────────────────────────────────────────────
  # Enami, Lustig et Aranda (CEQ Handbook, 2022). La contribution marginale d'un
  # instrument est rapportée à ce que le même budget aurait produit s'il avait
  # été alloué de la façon la plus égalisatrice possible : remplissage par le bas
  # pour un bénéfice, écrêtement par le haut pour un prélèvement.
  fill_up_income <- function(y, w, budget) {
    if (!is.finite(budget) || budget <= 0) return(y)
    f <- function(lambda) sum(w * pmax(lambda - y, 0)) - budget
    borne_haute <- max(y) + budget / sum(w)
    stats::uniroot(f, lower = min(y), upper = borne_haute, tol = 1e-10)$root |>
      (\(lambda) pmax(y, lambda))()
  }
  skim_down_income <- function(y, w, budget) {
    if (!is.finite(budget) || budget <= 0) return(y)
    f <- function(lambda) sum(w * pmax(y - lambda, 0)) - budget
    borne_basse <- min(y) - budget / sum(w)
    stats::uniroot(f, lower = borne_basse, upper = max(y), tol = 1e-10)$root |>
      (\(lambda) pmin(y, lambda))()
  }
  optimal_reduction <- function(y, w, budget, type) {
    depart <- weighted_gini(pmax(y, 0), w)
    optimum <- if (type == "bénéfice") fill_up_income(y, w, budget) else
      skim_down_income(y, w, budget)
    depart - weighted_gini(pmax(optimum, 0), w)
  }
  effectiveness <- purrr::map_dfr(seq_along(labels), function(i) {
    sans <- final_income - obj$effects[, i]
    budget <- sum(abs(obj$effects[, i]) * hh$pcweight)
    type <- if (names(labels)[[i]] %in% c("direct_levies", "indirect_taxes"))
      "prélèvement" else "bénéfice"
    contribution <- marginal$contribution_marginale[[i]]
    maximum <- optimal_reduction(sans, hh$pcweight, budget, type)
    # Budget minimal qui, alloué de façon optimale, atteindrait la contribution
    # effectivement observée. La réduction optimale croît avec le budget, ce qui
    # rend la recherche par dichotomie bien posée.
    part_budget <- if (!is.finite(contribution) || contribution <= 0 ||
                       !is.finite(maximum) || maximum <= 0) {
      NA_real_
    } else if (contribution >= maximum) {
      1
    } else {
      stats::uniroot(function(s) optimal_reduction(sans, hh$pcweight, s * budget, type) -
                       contribution, lower = 1e-8, upper = 1, tol = 1e-10)$root
    }
    tibble::tibble(
      instrument = names(labels)[[i]], libelle = labels[[i]], type = type,
      # pcweight = hhweight x hhsize, donc un montant par tête pondéré par
      # pcweight redonne exactement la masse nationale en FCFA.
      budget_milliards = budget / 1e9,
      contribution_marginale = contribution,
      reduction_maximale_meme_budget = maximum,
      efficacite_impact = contribution / maximum,
      efficacite_depense = part_budget,
      lecture = "Efficacité d'impact : part de la réduction du Gini atteignable au même budget")
  })

  reps <- 500L; seed <- 20240924L; set.seed(seed)
  boot <- matrix(NA_real_, nrow = reps, ncol = length(labels), dimnames = list(NULL, names(labels)))
  boot_p0 <- matrix(NA_real_, nrow = reps, ncol = length(labels), dimnames = list(NULL, names(labels)))
  boot_p1 <- matrix(NA_real_, nrow = reps, ncol = length(labels), dimnames = list(NULL, names(labels)))
  for (b in seq_len(reps)) {
    d <- hh
    # Un seul tirage de poids répliqués par itération : la suite aléatoire du
    # bootstrap du Gini est inchangée, les décompositions de pauvreté utilisent
    # exactement les mêmes réplications.
    d$pcweight <- rao_wu_weights(hh, "pcweight", "grappe", "strata")
    boot[b, ] <- tryCatch(as.numeric(shapley_core(d, "pdi")), error = function(e) rep(NA_real_, length(labels)))
    boot_p0[b, ] <- tryCatch(as.numeric(shapley_core(d, "pdi", poverty_index(0))),
                             error = function(e) rep(NA_real_, length(labels)))
    boot_p1[b, ] <- tryCatch(as.numeric(shapley_core(d, "pdi", poverty_index(1))),
                             error = function(e) rep(NA_real_, length(labels)))
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

  convergence_sizes <- c(50L, 100L, 200L, 500L)
  convergence <- purrr::map_dfr(convergence_sizes, function(n_rep) {
    purrr::map_dfr(seq_along(labels), function(i) {
      x <- boot[seq_len(n_rep), i]
      x <- x[is.finite(x)]
      tibble::tibble(
        repetitions = n_rep,
        instrument = names(labels)[[i]],
        libelle = labels[[i]],
        moyenne = mean(x),
        ecart_type = stats::sd(x),
        ic95_bas = unname(stats::quantile(x, 0.025)),
        ic95_haut = unname(stats::quantile(x, 0.975))
      )
    })
  })

  poverty_bootstrap <- purrr::map_dfr(
    list(list(mat = boot_p0, indice = "FGT0 : incidence", table = shapley_p0),
         list(mat = boot_p1, indice = "FGT1 : profondeur", table = shapley_p1)),
    function(bloc) {
      point <- dplyr::filter(bloc$table, convention == "PDI")
      purrr::map_dfr(seq_along(labels), function(i) {
        x <- bloc$mat[, i]; x <- x[is.finite(x)]
        tibble::tibble(indice = bloc$indice, instrument = names(labels)[[i]],
          libelle = labels[[i]],
          estimation = point$contribution_pauvrete[
            match(names(labels)[[i]], point$instrument)],
          ic95_bas = unname(stats::quantile(x, 0.025)),
          ic95_haut = unname(stats::quantile(x, 0.975)),
          ecart_type = stats::sd(x), repetitions_valides = length(x),
          methode = "Bootstrap Rao-Wu; Shapley exacte à chaque réplication")
      })
    })

  save_parquet(shapley_pdi, file.path(paths$SILVER, "23", "marginal_contributions.parquet"))
  save_parquet(dplyr::bind_rows(shapley_p0, shapley_p1),
               file.path(paths$SILVER, "23", "shapley_poverty.parquet"))
  export_excel(shapley_pdi, file.path(paths$TABLES, "23", "23_01_shapley_pdi.xlsx"))
  export_excel(shapley_pgt, file.path(paths$TABLES, "23", "23_02_shapley_pgt.xlsx"))
  export_excel(marginal, file.path(paths$TABLES, "23", "23_03_marginal_contributions.xlsx"))
  export_excel(progressivity, file.path(paths$TABLES, "23", "23_04_progressivity_targeting.xlsx"))
  export_excel(bootstrap, file.path(paths$TABLES, "23", "23_05_shapley_inference.xlsx"))
  export_excel(convergence, file.path(paths$TABLES, "23", "23_06_shapley_convergence.xlsx"))
  export_excel(shapley_p0, file.path(paths$TABLES, "23", "23_07_shapley_poverty_p0.xlsx"))
  export_excel(shapley_p1, file.path(paths$TABLES, "23", "23_08_shapley_poverty_p1.xlsx"))
  export_excel(poverty_bootstrap,
               file.path(paths$TABLES, "23", "23_09_shapley_poverty_inference.xlsx"))
  export_excel(reranking, file.path(paths$TABLES, "23", "23_10_reranking.xlsx"))
  export_excel(effectiveness, file.path(paths$TABLES, "23", "23_11_effectiveness.xlsx"))

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

  fig_poverty_data <- dplyr::bind_rows(shapley_p0, shapley_p1) |>
    dplyr::filter(convention == "PDI") |>
    dplyr::mutate(
      sens = dplyr::if_else(contribution_pauvrete >= 0,
        "Réduit la pauvreté", "Accroît la pauvreté"),
      libelle = factor(libelle, levels = rev(unname(labels))))
  fig_poverty <- ggplot2::ggplot(fig_poverty_data,
      ggplot2::aes(contribution_pauvrete, libelle, fill = sens)) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::geom_vline(xintercept = 0, color = "#4D4D4D") +
    ggplot2::facet_wrap(~ indice, scales = "free_x") +
    ggplot2::scale_fill_manual(values = c("Réduit la pauvreté" = "#1F77B4",
                                          "Accroît la pauvreté" = "#D62728")) +
    ggplot2::labs(
      title = "Contribution de chaque instrument à la variation de la pauvreté",
      subtitle = "Décomposition de Shapley, convention pensions comme revenu différé",
      x = "Réduction de l'indice (valeur positive)", y = NULL, fill = NULL) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(legend.position = "bottom")
  export_fig(fig_poverty, file.path(paths$FIGS, "fig23b_shapley_poverty.png"),
             width = 10, height = 6)

  message(sprintf("  Gini initial %.4f; final %.4f; réduction %.4f", g_base, g_final, g_base - g_final))
  p0_total <- shapley_p0$variation_totale[shapley_p0$convention == "PDI"][[1]]
  # variation_totale est une réduction : positive quand l'intervention fait
  # reculer l'indice.
  message(sprintf("  Réduction totale de l'incidence de la pauvreté : %+.2f point",
                  100 * p0_total))
  reclassement_total <- reranking$reclassement[
    reranking$element == "Revenu primaire vers revenu final"]
  message(sprintf("  Reclassement du revenu primaire au revenu final : %.5f",
                  reclassement_total))
  invisible(shapley_pdi)
}