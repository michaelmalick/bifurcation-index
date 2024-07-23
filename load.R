## LOAD PACKAGES, DATA, AND FUNCTIONS
## Michael Malick


cat("  Loading libraries...", "\n")
suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(sf))
suppressPackageStartupMessages(library(rworldmap))
library(ncdf4)
library(plyr)
library(raster)
library(ggsimple)   ## https://github.com/michaelmalick/ggsimple
data(countriesLow)


dir.create("./figures/", showWarnings = FALSE)
dir.create("./output/", showWarnings = FALSE)
dir.create("./share/", showWarnings = FALSE)

cat("  Loading functions...", "\n")
source("./functions.R")

cat("  Loading saved ouput...", "\n")
for(i in list.files(path = "./output/", pattern = "RData$"))
    load(paste("./output/", i, sep = ""))
rm(i)

cat("  Done!", "\n")
