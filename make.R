## REPRODUCE PROJECT
## Michael Malick


unlink("./figures", recursive = TRUE)
unlink("./output", recursive = TRUE)

rm(list = ls())

cat("Sourcing load.R ...", "\n");    source("./load.R")
cat("Sourcing oscurs.R ...", "\n");  source("./oscurs.R")
cat("Done!", "\n")
