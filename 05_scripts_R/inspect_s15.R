library(haven)
data <- read_dta("01_data_sources/Datain/Menage/s15_me_CIV2021.dta", n_max = 5)
print(colnames(data))
print(sapply(data, function(x) attr(x, "label")))
