# utils/distributive.R
#
# Weighted distributive indices used in CEQ-style analysis:
#   - Gini coefficient
#   - Concentration index
#   - Kakwani index
#   - Reynolds-Smolensky
#   - Decomposition equite verticale / reclassement (Atkinson-Plotnick)
#   - Weighted ntile (equivalent of Stata xtile with pw)
#   - Bootstrap Kakwani CI
#
# All indices use the midpoint-rule weighted fractional rank,
# consistent with Stata's -conindex- command.


# ── Weighted fractional rank ──────────────────────────────────────────────────
# Returns the midpoint-rule weighted fractional rank for observations
# ranked by `rankvar`. Formula: F_i = (CW_{i-1} + w_i/2) / W
weighted_frac_rank <- function(rankvar, w) {
  ord  <- order(rankvar)
  w_s  <- w[ord]
  cumw <- cumsum(w_s)
  totw <- sum(w_s)
  frac <- (cumw - w_s / 2) / totw
  result <- numeric(length(rankvar))
  result[ord] <- frac
  result
}


# ── Weighted mean ─────────────────────────────────────────────────────────────
wt_mean <- function(x, w) sum(x * w, na.rm = TRUE) / sum(w, na.rm = TRUE)


# ── Weighted Gini coefficient ─────────────────────────────────────────────────
# Uses the concentration index formula with x ranked by itself.
# Formula: G = 2 * sum_w(x_i * F_i) / (mu * W) - 1
weighted_gini <- function(x, w) {
  stopifnot(all(x >= 0, na.rm = TRUE), all(w >= 0, na.rm = TRUE),
            sum(w, na.rm = TRUE) > 0)
  F    <- weighted_frac_rank(x, w)
  mu   <- wt_mean(x, w)
  totw <- sum(w)
  2 * sum(w * x * F, na.rm = TRUE) / (mu * totw) - 1
}


# ── Weighted concentration index ──────────────────────────────────────────────
# t       : variable of interest (e.g., VAT paid) — must be >= 0
# rankvar : welfare ranking variable (e.g., consumption)
# w       : survey weights
weighted_conindex <- function(t, rankvar, w) {
  stopifnot(all(t >= 0, na.rm = TRUE), all(w >= 0, na.rm = TRUE),
            sum(w, na.rm = TRUE) > 0)
  F    <- weighted_frac_rank(rankvar, w)
  mu   <- wt_mean(t, w)
  totw <- sum(w)
  2 * sum(w * t * F, na.rm = TRUE) / (mu * totw) - 1
}


# ── Kakwani index ─────────────────────────────────────────────────────────────
# Kakwani = CI(tax) - Gini(welfare)
# > 0 : progressive  (richer households bear proportionally more)
# < 0 : regressive   (poorer households bear proportionally more)
kakwani_index <- function(t, welfare, w) {
  ci  <- weighted_conindex(t, welfare, w)
  gin <- weighted_gini(welfare, w)
  ci - gin
}


# ── Reynolds-Smolensky ────────────────────────────────────────────────────────
# Convention CEQ standard : RS = Gini(before) - Gini(after).
# > 0 : l'intervention réduit l'inégalité.
# < 0 : l'intervention accroît l'inégalité.
reynolds_smolensky <- function(welfare_before, welfare_after, w) {
  weighted_gini(welfare_before, w) - weighted_gini(welfare_after, w)
}


# ── Decomposition equite verticale / reclassement ─────────────────────────────
# Atkinson (1980), Plotnick (1981) : la reduction d'inegalite mesuree par
# Reynolds-Smolensky se scinde en un effet d'equite verticale et un effet de
# reclassement des menages.
#
#   RS = G(avant) - G(apres)
#   VE = G(avant) - C(apres | rang avant)     equite verticale
#   R  = G(apres) - C(apres | rang avant)     reclassement, toujours >= 0
#   RS = VE - R
#
# Le reclassement est nul si l'intervention preserve l'ordre des menages. Un
# reclassement positif signale que l'intervention deplace des menages les uns
# par rapport aux autres, meme lorsqu'elle reduit l'inegalite globale.
#
# Comme partout ailleurs dans la chaine, les revenus sont plancher a zero avant
# le calcul des indices : l'indice de concentration n'est defini que sur une
# variable positive.
reranking_decomposition <- function(welfare_before, welfare_after, w) {
  before <- pmax(welfare_before, 0)
  after  <- pmax(welfare_after, 0)
  gini_before <- weighted_gini(before, w)
  gini_after  <- weighted_gini(after, w)
  conc_after  <- weighted_conindex(after, before, w)
  list(
    gini_avant = gini_before,
    gini_apres = gini_after,
    concentration_apres_rang_avant = conc_after,
    reynolds_smolensky = gini_before - gini_after,
    equite_verticale = gini_before - conc_after,
    reclassement = gini_after - conc_after
  )
}


# ── Weighted quantile ─────────────────────────────────────────────────────────
# Simple implementation of weighted quantile using linear interpolation.
# Equivalent to Stata's -centile- with weights.
weighted_quantile <- function(x, w, probs) {
  ord  <- order(x)
  x_s  <- x[ord]
  w_s  <- w[ord]
  cumw <- cumsum(w_s) / sum(w_s)
  sapply(probs, function(p) {
    idx <- which(cumw >= p)
    if (length(idx) == 0) return(max(x_s))
    x_s[idx[1]]
  })
}


# ── Weighted ntile ────────────────────────────────────────────────────────────
# Equivalent of Stata: xtile var = x [pw=w], n(n)
# Returns integer assignments 1..n based on weighted quantile cuts.
weighted_ntile <- function(x, w, n = 10) {
  totw <- sum(w)
  ord  <- order(x)
  x_s  <- x[ord]
  w_s  <- w[ord]
  cumw <- cumsum(w_s)

  # Compute weighted quantile cut points
  wquantiles <- numeric(n - 1)
  for (i in seq_len(n - 1)) {
    target <- totw * i / n
    idx <- which(cumw >= target)
    if (length(idx) == 0) {
      wquantiles[i] <- max(x_s)
    } else {
      wquantiles[i] <- x_s[idx[1]]
    }
  }

  breaks <- c(-Inf, wquantiles, Inf)
  result <- findInterval(x, breaks, rightmost.closed = TRUE)
  result <- pmin(pmax(result, 1L), as.integer(n))
  result
}


# ── Bootstrap Kakwani confidence interval ────────────────────────────────────
# Returns 95% percentile CI on Kakwani via non-parametric bootstrap.
# Standard in CEQ analysis (Lustig 2018, CEQ Handbook): 500 reps.
bootstrap_kakwani_iid <- function(data, tax_var, welfare_var, weight_var,
                                  reps = 500, seed = 20240901, level = 0.95) {
  set.seed(seed)
  t   <- data[[tax_var]]
  wel <- data[[welfare_var]]
  w   <- data[[weight_var]]
  n   <- nrow(data)

  kak_boot <- replicate(reps, {
    idx <- sample(n, n, replace = TRUE)
    tryCatch(
      kakwani_index(t[idx], wel[idx], w[idx]),
      error = function(e) NA_real_
    )
  })

  kak_boot <- kak_boot[!is.na(kak_boot)]
  alpha    <- 1 - level

  list(
    mean = mean(kak_boot),
    lo   = unname(quantile(kak_boot, alpha / 2)),
    hi   = unname(quantile(kak_boot, 1 - alpha / 2)),
    sd   = sd(kak_boot)
  )
}


# Rao-Wu rescaled bootstrap weights for a stratified multistage design.
# Within each stratum, m_h - 1 PSUs are drawn with replacement from m_h PSUs.
rao_wu_weights <- function(data, weight_var, cluster_var, strata_var) {
  stopifnot(all(c(weight_var, cluster_var, strata_var) %in% names(data)))

  strata <- interaction(data[[strata_var]], drop = TRUE, lex.order = TRUE)
  cluster <- interaction(strata, data[[cluster_var]], drop = TRUE,
                         lex.order = TRUE)
  multiplier <- numeric(nrow(data))

  for (h in levels(strata)) {
    in_h <- which(strata == h)
    psu_h <- unique(cluster[in_h])
    m_h <- length(psu_h)

    if (m_h < 2L) {
      multiplier[in_h] <- 1
      next
    }

    selected <- sample(psu_h, m_h - 1L, replace = TRUE)
    counts <- table(selected)
    multiplier[in_h] <- as.numeric(counts[as.character(cluster[in_h])])
    multiplier[in_h][is.na(multiplier[in_h])] <- 0
    multiplier[in_h] <- multiplier[in_h] * m_h / (m_h - 1L)
  }

  data[[weight_var]] * multiplier
}


# Generic percentile interval using the survey design bootstrap.
bootstrap_survey_statistic <- function(data, statistic, weight_var,
                                       cluster_var = NULL, strata_var = NULL,
                                       reps = 500, seed = 20240901,
                                       level = 0.95) {
  set.seed(seed)
  use_design <- !is.null(cluster_var) && !is.null(strata_var) &&
    all(c(cluster_var, strata_var) %in% names(data))
  estimates <- replicate(reps, {
    d <- data
    if (use_design) {
      d[[weight_var]] <- rao_wu_weights(data, weight_var, cluster_var, strata_var)
    } else {
      d <- data[sample.int(nrow(data), nrow(data), replace = TRUE), , drop = FALSE]
    }
    tryCatch(statistic(d), error = function(e) NA_real_)
  })
  estimates <- estimates[is.finite(estimates)]
  alpha <- 1 - level
  list(mean = mean(estimates),
       lo = unname(quantile(estimates, alpha / 2)),
       hi = unname(quantile(estimates, 1 - alpha / 2)),
       sd = sd(estimates), reps_ok = length(estimates),
       method = if (use_design) 'Rao-Wu rescaled bootstrap' else 'iid bootstrap')
}


# Kakwani interval. Supplying cluster and strata invokes design inference.
bootstrap_kakwani <- function(data, tax_var, welfare_var, weight_var,
                              cluster_var = NULL, strata_var = NULL,
                              reps = 500, seed = 20240901, level = 0.95) {
  bootstrap_survey_statistic(
    data = data,
    statistic = function(d) {
      kakwani_index(d[[tax_var]], d[[welfare_var]], d[[weight_var]])
    },
    weight_var = weight_var, cluster_var = cluster_var,
    strata_var = strata_var, reps = reps, seed = seed, level = level
  )
}


# Foster-Greer-Thorbecke index: headcount, gap and severity for alpha 0, 1, 2.
fgt_index <- function(welfare, poverty_line, w, alpha = 0) {
  if (alpha == 0) return(wt_mean(as.numeric(welfare < poverty_line), w))
  gap <- pmax((poverty_line - welfare) / poverty_line, 0)
  wt_mean(gap^alpha, w)
}
