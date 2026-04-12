# config.R
#
# Centralized configuration for the pipeline.
# Controls data source (local vs MinIO) and environment parameters.
#
# ── Usage ─────────────────────────────────────────────────────────────────────
# Set USE_MINIO = TRUE when on the institutional network with MinIO access.
# Set USE_MINIO = FALSE for local development (default).
#
# MinIO credentials are read from environment variables — never hardcoded.
# Copy .env.example to .env and fill in your values:
#   source("05_scripts_R/config.R")  will load .env automatically if present.

# ── Data source flag ──────────────────────────────────────────────────────────
USE_MINIO <- FALSE   # <- flip to TRUE when MinIO is available

# ── MinIO connection parameters ───────────────────────────────────────────────
# Read from environment variables (set in .env or system environment)
MINIO_ENDPOINT   <- Sys.getenv("MINIO_ENDPOINT",   unset = "http://minio.institution.local:9000")
MINIO_BUCKET_RAW <- Sys.getenv("MINIO_BUCKET_RAW", unset = "anstat-raw")      # bronze: raw .dta
MINIO_BUCKET_SIL <- Sys.getenv("MINIO_BUCKET_SIL", unset = "anstat-silver")   # silver: parquet
MINIO_ACCESS_KEY <- Sys.getenv("MINIO_ACCESS_KEY", unset = "")
MINIO_SECRET_KEY <- Sys.getenv("MINIO_SECRET_KEY", unset = "")

# ── Load .env if present (never committed to git) ─────────────────────────────
env_file <- file.path(ROOT, ".env")
if (file.exists(env_file)) {
  lines <- readLines(env_file, warn = FALSE)
  lines <- lines[!grepl("^\\s*#", lines) & nchar(trimws(lines)) > 0]
  for (line in lines) {
    parts <- strsplit(line, "=", fixed = TRUE)[[1]]
    if (length(parts) >= 2) {
      key <- trimws(parts[1])
      val <- trimws(paste(parts[-1], collapse = "="))
      val <- gsub('^"|"$|^\'|\'$', "", val)   # strip quotes
      do.call(Sys.setenv, setNames(list(val), key))
    }
  }
  # Re-read after loading .env
  MINIO_ENDPOINT   <- Sys.getenv("MINIO_ENDPOINT",   unset = MINIO_ENDPOINT)
  MINIO_BUCKET_RAW <- Sys.getenv("MINIO_BUCKET_RAW", unset = MINIO_BUCKET_RAW)
  MINIO_BUCKET_SIL <- Sys.getenv("MINIO_BUCKET_SIL", unset = MINIO_BUCKET_SIL)
  MINIO_ACCESS_KEY <- Sys.getenv("MINIO_ACCESS_KEY", unset = MINIO_ACCESS_KEY)
  MINIO_SECRET_KEY <- Sys.getenv("MINIO_SECRET_KEY", unset = MINIO_SECRET_KEY)
  message("  .env loaded")
}

if (USE_MINIO) {
  if (MINIO_ACCESS_KEY == "" || MINIO_SECRET_KEY == "") {
    stop("USE_MINIO=TRUE but MINIO_ACCESS_KEY / MINIO_SECRET_KEY are not set.\n",
         "Copy .env.example to .env and fill in your credentials.")
  }
  message("  Data source: MinIO (", MINIO_ENDPOINT, ")")
} else {
  message("  Data source: local (", DATA, ")")
}
