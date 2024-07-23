## PROCESS OSCURS MODEL DATA + CALC BI
## Michael Malick

yrs = 1967:2024


if(!file.exists("./data/oscurs"))
    utils::unzip("./data/oscurs.zip", exdir = "./data/oscurs")
if(!file.exists("./data/landmask"))
    utils::unzip("./data/landmask.zip", exdir = "./data/landmask")


## 1. Determine grid to run OSCURS model on ----------------
grd <- rbind(
    matrix(c(-145:-124, rep(39, 22)), ncol = 2),
    matrix(c(-145:-124, rep(38, 22)), ncol = 2),
    matrix(c(-145:-123, rep(37, 23)), ncol = 2),
    matrix(c(-145:-122, rep(36, 24)), ncol = 2),
    matrix(c(-145:-121, rep(35, 25)), ncol = 2),
    matrix(c(-145:-125, rep(40, 21)), ncol = 2),
    matrix(c(-145:-125, rep(41, 21)), ncol = 2),
    matrix(c(-145:-125, rep(42, 21)), ncol = 2),
    matrix(c(-145:-125, rep(43, 21)), ncol = 2),
    matrix(c(-145:-125, rep(44, 21)), ncol = 2),
    matrix(c(-145:-125, rep(45, 21)), ncol = 2),
    matrix(c(-145:-125, rep(46, 21)), ncol = 2),
    matrix(c(-145:-125, rep(47, 21)), ncol = 2),
    matrix(c(-145:-125, rep(48, 21)), ncol = 2),
    matrix(c(-145:-126, rep(49, 20)), ncol = 2),
    matrix(c(-145:-128, rep(50, 18)), ncol = 2),
    matrix(c(-145:-129, rep(51, 17)), ncol = 2),
    matrix(c(-145:-132, rep(52, 14)), ncol = 2),
    matrix(c(-145:-133, rep(53, 13)), ncol = 2),
    matrix(c(-145:-134, rep(54, 12)), ncol = 2),
    matrix(c(-145:-134, rep(55, 12)), ncol = 2),
    matrix(c(-145:-135, rep(56, 11)), ncol = 2),
    matrix(c(-145:-136, rep(57, 10)), ncol = 2),
    matrix(c(-145:-137, rep(58, 9)), ncol = 2),
    matrix(c(-145:-139, rep(59, 7)), ncol = 2))
grd <- data.frame(lon = grd[,1], lat = grd[,2])

pdf("./figures/drifter_grid.pdf", width = 5, height = 5)
    g <- ggplot(grd) +
        geom_sf(data = st_as_sf(countriesLow), fill = "grey90",
                color = "grey30", size = 0.2) +
        geom_point(aes(x = lon, y = lat), size = 1) +
        labs(x = "Longitude",
             y = "Latitude") +
        xlim(-160, -120) +
        ylim(34, 60) +
        theme_simple(grid = TRUE)
    print(g)
dev.off()


# Number of grid cells
length(grd[ , 1])

# Degrees west
plyr::ddply(grd, .(lat), summarize,
            lon.min = range(lon)[1],
            lon.max = range(lon)[2],
            n.lon = length(lon),
            runs = length(lon) * 48) # 48 years (1967:2014)

# Degrees east
plyr::ddply(grd, .(lat), summarize,
            lon.min = range(lon)[1] + 360,
            lon.max = range(lon)[2] + 360,
            n.lon = length(lon),
            runs = length(lon) * 48) # 48 years (1967:2014)

# Total runs
total_runs <- plyr::ddply(grd, .(lat), summarize,
                          lon.min = range(lon)[1] + 360,
                          lon.max = range(lon)[2] + 360,
                          n.lon = length(lon),
                          runs = length(lon) * 48) # 48 years (1967:2014)
sum(total_runs$runs)



## 2. Read and process raw OSCURS data ---------------------
files <- list.files(path = "./data/oscurs",
                    full.names = TRUE,
                    recursive = TRUE)
nfiles <- length(files)
pb <- txtProgressBar(min = 0, max = nfiles, style = 3)
lst <- vector("list", nfiles)
for(i in seq_along(files)) {
    fname <- files[i]
    tmp   <- read.csv(fname, skip = 3)
    n_dat <- nrow(tmp)
    names(tmp) <- c("date", "lat", "lon.e")
    tmp$date   <- as.POSIXlt(tmp$date)
    tmp$lon    <- tmp$lon.e - 360
    tmp$year   <- as.numeric(format(tmp$date, "%Y"))
    tmp$ind    <- 1:length(tmp$lon)
    tmp$end    <- ifelse(tmp$lat[1] >= tmp$lat[n_dat], "south", "north")
    tmp$end    <- ifelse(tmp$lon[n_dat] < -144, "north", tmp$end)
    tmp$run    <- i
    tmp$start.lon <- as.numeric(substr(fname, 24,26)) * -1
    tmp$start.lat <- as.numeric(substr(fname, 20,21))
    tmp$date      <- as.character(tmp$date)
    lst[[i]]      <- tmp
    setTxtProgressBar(pb, i)
}
close(pb)
oscurs <- plyr::rbind.fill(lst)
save(oscurs, file = "./output/oscurs.RData")



## 3. Apply land mask --------------------------------------
## The raw OSCURS model runs downloaded from the website
## DO NOT stop when the drifter hits land. Therefore, a
## land mask needs to be applied to the runs to truncate
## the run if the drifter hits land.

## Read in landmask
pth <- "./data/landmask/NAVO-lsmask-world8-var.dist5.5.nc"
rt  <- raster::raster(pth, varname = "dst")
rtc <- raster::crop(rt, c(-175, -90, 10, 70))

## Extract oscurs points that are not over land
ex <- raster::extract(rtc, oscurs[ , c("lon", "lat")])
oscurs_mm <- oscurs[is.na(ex) | ex > 0, ]

## Need to truncate drifter track if it hit land and went back to the ocean
lst <- split(oscurs_mm, oscurs_mm$run)
msk <- lapply(lst, function(x) {
    ind <- diff(x$ind)
    if(!all(ind == 1)) {
        i <- which(ind != 1)[1]
        x <- x[1:i, ]
    }
    ## need to recalc if drifter ended north or south
    x$end <- ifelse(x$lat[1] > x$lat[nrow(x)], "south", "north")
    return(x)
})
oscurs_mask <- plyr::rbind.fill(msk)
save(oscurs_mask, file = "./output/oscurs_mask.RData")



## 4. Calculate bifurcation index --------------------------
oscurs_index <- subset_grid(oscurs_mask,
                            east  = -125,
                            west  = -140,
                            north = 55,
                            south = 40)
save(oscurs_index, file = "./output/oscurs_index.RData")

bi_main <- bi_calc(oscurs_index,
                   method = "percent-all",
                   type = "mask",
                   grid = "small")
save(bi_main, file = "./output/bi_main.RData")



## 5. Plotting ---------------------------------------------

## BI time series
pdf("./figures/bi_time_series.pdf", width = 6, height = 4)
    g <- ggplot(bi_main) +
        aes(x = year, y = bi) +
        geom_hline(yintercept = mean(bi_main$bi),
                   color = "grey50", linetype = 2) +
        geom_point() +
        geom_line() +
        labs(x = "Year",
             y = "Bifurcation index") +
        theme_simple()
    print(g)
dev.off()


## Drifters plotted by year (individual)
plot_drifters(data = oscurs_index, years = yrs, type = "indv",
              file = "./figures/drifters.pdf")


## Plot drifter grid colored by end position
plot_grid_end(data = oscurs_index, years = yrs,
              type = "all", file = "./figures/grid_end.pdf")



## 6. Export CSV -------------------------------------------
ex <- data.frame(year = bi_main[["year"]],
                 bifurcation_index = bi_main[["bi"]])

header <-"# Bifurcation Index
#
# Malick, M.J., et al. 2017. Effects of the North Pacific Current on the
# productivity of 163 Pacific salmon stocks. Fisheries Oceanography 26:268--281.
# <https://doi.org/10.1111/fog.12190>
#
# bifurcation index: percentage of the 215 simulated drifters that ended south
#                    of their starting latitude in a particular year
#
# Michael Malick <malickmj@gmail.com>
"
header <- paste0(header, "# Updated: ", Sys.time())

file <- "./share/bifurcation_index.csv"
write.table(header, file, quote = FALSE,
            row.names = FALSE, col.names = FALSE)
suppressWarnings(  ## suppress warning about appending column names
write.table(ex, file, quote = FALSE,
            sep = ",", append = TRUE,
            row.names = FALSE, col.names = TRUE))
