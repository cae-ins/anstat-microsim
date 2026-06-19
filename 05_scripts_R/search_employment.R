library(haven)
files <- list.files("01_data_sources/Datain/Menage", pattern = "\\.dta$", full.names = TRUE)

for (f in files) {
  try({
    data <- read_dta(f, n_max = 1)
    labels <- sapply(data, function(x) attr(x, "label"))
    if (any(grepl("salaire|emploi|profession|travail", labels, ignore.case = TRUE))) {
      cat("Found match in:", f, "\n")
      # Print first few matching labels
      print(labels[grepl("salaire|emploi|profession|travail", labels, ignore.case = TRUE)][1:5])
    }
  }, silent = TRUE)
}
