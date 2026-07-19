find_root <- function(start = getwd()) {
  p <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(p, "05_scripts_R", "00_master.R"))) return(p)
    parent <- dirname(p)
    if (identical(parent, p)) stop("Racine du dépôt introuvable.", call. = FALSE)
    p <- parent
  }
}

verify_main <- function(stop_on_fail = TRUE) {
  root <- find_root(); old <- setwd(root); on.exit(setwd(old), add = TRUE)
  out_dir <- file.path(root, "replication_package", "output")
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  rows <- list()
  add <- function(id, status, observed, expected = NA_real_, tolerance = NA_real_, detail = "") {
    rows[[length(rows) + 1L]] <<- data.frame(
      check = id, status = status, observed = observed, expected = expected,
      tolerance = tolerance, detail = detail, stringsAsFactors = FALSE
    )
  }
  required <- c(
    "07_reports/tables/25/CEQ_CIV_2021_master.xlsx",
    "02_data_intermediate/22/all_income_concepts.parquet",
    "02_data_intermediate/23/marginal_contributions.parquet",
    "02_data_intermediate/24/fiscal_impoverishment.parquet",
    "02_data_intermediate/18/transfers.parquet",
    "07_reports/tables/18/18_02_coverage_targeting.xlsx",
    "07_reports/tables/06/06_03_vat_informality_parameters.xlsx",
    "07_reports/tables/13/13_07_legal_deduction_sensitivity.xlsx",
    "07_reports/tables/16/16_07_robustness_diagnostics.xlsx",
    "replication_package/exhibit_map.csv"
  )
  for (p in required) add(p, if (file.exists(p)) "PASS" else "FAIL",
                          as.numeric(file.exists(p)), 1, 0, "présence")
  if (any(!file.exists(required))) {
    report <- do.call(rbind, rows)
    utils::write.csv(report, file.path(out_dir, "verification_report.csv"), row.names = FALSE)
    if (stop_on_fail) stop("Sorties maîtres absentes.", call. = FALSE)
    return(invisible(report))
  }

  exhibit_map <- utils::read.csv(
    file.path(root, "replication_package", "exhibit_map.csv"),
    stringsAsFactors = FALSE, check.names = FALSE
  )
  mapped_outputs <- trimws(unlist(strsplit(exhibit_map$output, ";", fixed = TRUE)))
  missing_outputs <- mapped_outputs[!file.exists(mapped_outputs)]
  add(
    "carte exhibits : sorties",
    if (length(missing_outputs) == 0L) "PASS" else "FAIL",
    length(missing_outputs), 0, 0,
    if (length(missing_outputs)) paste(missing_outputs, collapse = " | ") else "34 sorties accessibles"
  )
  aux_path <- file.path(root, "00_documentation", "working_paper", "DT_CEQ_CIV2021.aux")
  aux_text <- paste(readLines(aux_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  aux_labels <- unique(unlist(regmatches(
    aux_text, gregexpr("(?<=\\\\newlabel\\{)(?:tab|fig):[^}]+", aux_text, perl = TRUE)
  )))
  map_labels <- unique(exhibit_map$manuscript_label)
  label_diff <- setdiff(union(aux_labels, map_labels), intersect(aux_labels, map_labels))
  add(
    "carte exhibits : labels",
    if (length(label_diff) == 0L) "PASS" else "FAIL",
    length(label_diff), 0, 0,
    if (length(label_diff)) paste(label_diff, collapse = " | ") else "34 labels en parité"
  )
  if (!requireNamespace("arrow", quietly = TRUE)) stop("arrow absent.")
  if (!requireNamespace("readxl", quietly = TRUE)) stop("readxl absent.")
  source(file.path(root, "05_scripts_R", "utils", "distributive.R"))
  hh <- arrow::read_parquet(required[[2]])
  shap <- arrow::read_parquet(required[[3]])
  fi <- arrow::read_parquet(required[[4]])
  tr <- arrow::read_parquet(required[[5]])

  id_yc <- max(abs(hh$yc_pc - (hh$yd_pc - hh$indirect_taxes_hh_real / hh$hhsize +
                                  hh$subsidy_total_hh_real / hh$hhsize)), na.rm = TRUE)
  id_yf <- max(abs(hh$yf_pc - (hh$yc_pc + hh$education_net_hh_real / hh$hhsize +
                                  hh$health_net_hh_real / hh$hhsize)), na.rm = TRUE)
  id_yp <- max(abs(hh$yp_pc_pdi - (hh$yd_pc + hh$direct_levies_pdi_hh_real / hh$hhsize -
                                      hh$public_transfers_hh_real / hh$hhsize)), na.rm = TRUE)
  for (z in list(c("identité Y_C", id_yc), c("identité Y_F", id_yf), c("identité Y_P PDI", id_yp))) {
    x <- as.numeric(z[[2]]); add(z[[1]], if (x <= 1e-6) "PASS" else "FAIL", x, 0, 1e-6)
  }
  shap_err <- max(abs(unique(shap$variation_totale) - sum(shap$contribution_gini)), na.rm = TRUE)
  add("fermeture Shapley", if (shap_err <= 1e-10) "PASS" else "FAIL", shap_err, 0, 1e-10)

  pmt <- readxl::read_excel(required[[6]], sheet = "pssn")
  pmt_value <- function(label) as.numeric(pmt$valeur[pmt$indicateur == label][[1]])
  values <- c(
    gini_revenu_primaire = weighted_gini(pmax(hh$yp_pc_pdi, 0), hh$pcweight),
    gini_revenu_final = weighted_gini(pmax(hh$yf_pc, 0), hh$pcweight),
    pauvrete_revenu_primaire = stats::weighted.mean(hh$yp_pc_pdi < hh$zref, hh$pcweight),
    pauvrete_revenu_consommable = stats::weighted.mean(hh$yc_pc < hh$zref, hh$pcweight),
    pauvrete_revenu_final = stats::weighted.mean(hh$yf_pc < hh$zref, hh$pcweight),
    nouveaux_pauvres_pdi = stats::weighted.mean(fi$fiscal_new_poor_pdi, fi$pcweight),
    perte_fiscale_milliards = sum(fi$fiscal_loss_pdi * fi$pcweight) / 1e9,
    gain_fiscal_milliards = sum(fi$fiscal_gain_pdi * fi$pcweight) / 1e9,
    pssn_masse_milliards = sum(tr$pssn_hh * tr$hhweight) / 1e9,
    pssn_facteur_calage = pmt_value("Facteur de calage de masse")
  )
  shap_key <- c(
    prelevements_directs = "direct_levies",
    paiements_publics = "direct_transfers",
    impots_indirects = "indirect_taxes",
    reductions_prix = "price_reductions",
    education = "education",
    sante = "health"
  )
  for (nm in names(shap_key)) {
    hit <- shap$contribution_gini[shap$instrument == shap_key[[nm]]]
    if (length(hit) == 1L) values[[paste0("shapley_", nm)]] <- hit
  }

  expected <- utils::read.csv(file.path(out_dir, "expected_metrics.csv"), stringsAsFactors = FALSE)
  for (i in seq_len(nrow(expected))) {
    id <- expected$metric[[i]]
    obs <- if (id %in% names(values)) unname(values[[id]]) else numeric()
    if (length(obs) == 0L || !is.finite(obs)) {
      add(id, "FAIL", NA_real_, expected$expected[[i]], expected$tolerance[[i]], "non calculé")
    } else {
      ok <- abs(obs - expected$expected[[i]]) <= expected$tolerance[[i]]
      add(id, if (ok) "PASS" else "FAIL", obs, expected$expected[[i]], expected$tolerance[[i]])
    }
  }
  report <- do.call(rbind, rows)
  utils::write.csv(report, file.path(out_dir, "verification_report.csv"), row.names = FALSE,
                   fileEncoding = "UTF-8")
  failures <- sum(report$status == "FAIL")
  message(sprintf("Vérification : %d PASS, %d FAIL.", sum(report$status == "PASS"), failures))
  if (stop_on_fail && failures > 0L) stop("Résultats non conformes.", call. = FALSE)
  invisible(report)
}

if (sys.nframe() == 0L) {
  tryCatch(verify_main(TRUE), error = function(e) {message(conditionMessage(e)); quit(status = 1L)})
}