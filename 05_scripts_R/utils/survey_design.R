# utils/survey_design.R
#
# Plans de sondage EHCVM utilises dans la microsimulation CEQ.
# L'unite d'estimation determine le poids :
#   - menage  : hhweight ;
#   - personne : pcweight = hhweight * hhsize.

validate_ceq_weights <- function(data, tolerance = 1e-10) {
  required <- c("hhweight", "pcweight", "hhsize", "grappe", "strata")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      "Variables du plan de sondage absentes : ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (anyNA(data$hhweight) || anyNA(data$pcweight) || anyNA(data$hhsize)) {
    stop("Poids ou taille du menage manquants.", call. = FALSE)
  }
  if (any(data$hhweight <= 0) || any(data$pcweight <= 0) ||
      any(data$hhsize <= 0)) {
    stop("Les poids et la taille du menage doivent etre strictement positifs.",
         call. = FALSE)
  }

  expected <- data$hhweight * data$hhsize
  relative_error <- abs(data$pcweight - expected) / pmax(1, abs(expected))
  if (max(relative_error) > tolerance) {
    stop(
      "pcweight doit etre exactement le poids de population hhweight * hhsize.",
      call. = FALSE
    )
  }

  psu_by_stratum <- tapply(
    as.character(data$grappe),
    as.character(data$strata),
    function(x) length(unique(x))
  )
  if (any(psu_by_stratum < 2L)) {
    bad <- names(psu_by_stratum)[psu_by_stratum < 2L]
    stop(
      "Strate(s) avec moins de deux grappes : ",
      paste(bad, collapse = ", "),
      ". Le traitement des unites primaires isolees doit etre documente.",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


ceq_survey_design <- function(data, unit = c("household", "person")) {
  if (!requireNamespace("survey", quietly = TRUE)) {
    stop("Le package survey est requis pour definir le plan EHCVM.",
         call. = FALSE)
  }
  unit <- match.arg(unit)
  data <- as.data.frame(data)
  validate_ceq_weights(data)
  weight_var <- if (identical(unit, "household")) "hhweight" else "pcweight"

  survey::svydesign(
    ids = stats::as.formula("~grappe"),
    strata = stats::as.formula("~strata"),
    weights = stats::as.formula(paste0("~", weight_var)),
    nest = TRUE,
    data = data
  )
}


ceq_survey_replicate_design <- function(data, unit = c("household", "person"),
                                        reps = 500, seed = 20240901) {
  unit <- match.arg(unit)
  set.seed(seed)
  survey::as.svrepdesign(
    ceq_survey_design(data, unit = unit),
    type = "bootstrap",
    replicates = reps,
    mse = TRUE
  )
}


survey_replicate_statistic <- function(replicate_design, statistic,
                                       level = 0.95) {
  result <- survey::withReplicates(
    replicate_design,
    function(weights, data) statistic(data, weights),
    return.replicates = TRUE
  )
  estimates <- as.numeric(result$replicates)
  estimates <- estimates[is.finite(estimates)]
  alpha <- 1 - level

  list(
    point = as.numeric(stats::coef(result)),
    mean = mean(estimates),
    lo = unname(stats::quantile(estimates, alpha / 2)),
    hi = unname(stats::quantile(estimates, 1 - alpha / 2)),
    sd = as.numeric(survey::SE(result)),
    reps_ok = length(estimates),
    method = "survey::svydesign + as.svrepdesign(type = 'bootstrap')"
  )
}
