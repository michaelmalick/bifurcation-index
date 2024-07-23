## FUNCTIONS FOR THE ANALYSIS
## Michael Malick


## bi_calc -------------------------------------------------
bi_calc <- function(data,
                    method,
                    type = NULL,
                    grid = NULL) {
    ## This function takes as input raw or truncated OSCUR model runs and
    ## calculates the bifurcation index. The output of the function is a data
    ## frame.
    ##
    ## Three methods for calculating the BI are available:
    ##   - watters-bessey
    ##       - sum of the differences between median start and end latitudes for
    ##         a particular longitude ensemble
    ##   - north-south-split
    ##       - median starting latitude for the first grid cell that went north
    ##         for a particular longitude ensemble
    ##   - percent-all
    ##       - percent of all grid cells that ended south of start latitude
    ##
    ## data = input data, e.g., oscurs.m
    ## method = character string identifying method used calculate BI
    ## type = character string identifying the data type (added to output df)

    if(method == "percent-all") {
        dat.sub <- data[data$ind == 1, ]
        bi <- plyr::ddply(dat.sub, .(year), summarize,
                          bi = sum(end == "south") / length(lat))

    }

    if(method == "watters-bessey") {
        sub.run <- plyr::ddply(data, .(run), summarize,
                               year = unique(year),
                               start.lon = unique(start.lon),
                               start.lat = unique(start.lat),
                               end.lat = tail(lat, 1))

        start.end <- plyr::ddply(sub.run, .(year, start.lon), summarize,
                                 med.start.lat = median(start.lat),
                                 med.end.lat = median(end.lat),
                                 bi = median(start.lat) - median(end.lat))

        bi <- plyr::ddply(start.end, .(year),
                          bi = sum(bi))
    }

    if(method == "north-south-split") {
        dat.sub   <- data[data$ind == 1, ]
        dat.split <- split(dat.sub, list(dat.sub$year, dat.sub$start.lon))
        ns.split  <- lapply(dat.split,
            function(x) {
                if(dim(x[x$end == "north", ])[1] > 0) {
                    x[which(x$end == "north")[1], ]
                } else {
                    tail(x, 1)
                }
            })
        ns.split <- plyr::rbind.fill(ns.split)

        bi <- plyr::ddply(ns.split, .(year), summarize,
                          bi = median(start.lat))
    }

    bi$method <- method

    if(!is.null(type))
        bi$type <- type

    if(!is.null(grid))
        bi$grid <- grid

    return(bi)
}



## plot_grid_end -------------------------------------------
plot_grid_end <- function(data, years, type, file = NULL) {
    ## This function takes as input raw or truncated OSCUR model runs and maps
    ## the starting position of each run, color coding by weather the drifter
    ## ended north or south of the starting latitude. The function does this for
    ## each year individually.
    ##
    ## data = oscur model runs
    ## years = vector of years
    ## type = 'all'; plot all years in a single plot
    ##        'indv'; plot each year in an indivial plot
    ## file = pdf file to save graphic to

    if(!is.null(file) & type == "all")
        pdf(file, width = 14, height = 10)

    if(!is.null(file) & type == "indv")
        pdf(file, width = 6, height = 6)

    if(type == "all")
        par(mfrow = c(7, 7), mar = c(0, 0, 0, 0), oma = c(1, 1, 1, 1))

    if(type == "indv")
        par(mar = c(0, 0, 0, 0), oma = c(1, 1, 1, 1))

    for(j in years) {
        dat.sub <- data[data$year == j, ]
        grid2   <- dat.sub[dat.sub$ind == 1, ]
        grid2.n <- grid2[grid2$end == "north", ]
        grid2.s <- grid2[grid2$end == "south", ]
        plot(1, 1, type = "n",
            xlim = c(-160, -120),
            ylim = c(30, 60),
            ylab = "",
            xlab = "",
            axes = FALSE)
        plot(countriesLow, add = TRUE,
            col = "grey80",
            border = "grey70",
            lwd = 0.5)
        points(grid2.n$lon, grid2.n$lat, pch = 16, cex = 0.8,
               col = "steelblue")
        points(grid2.s$lon, grid2.s$lat, pch = 16, cex = 0.8,
            col = "tomato")
        text(x = -123, y = 59, labels = paste(j))
        box(col = "grey70")
    }

    if(!is.null(file))
        dev.off()
}



## plot_drifters -------------------------------------------
plot_drifters <- function(data, years, type, file = NULL) {
    ## This function takes as input raw or truncated OSCUR model runs and maps
    ## each drifter path for each year, color coding by weather the drifter
    ## ended north or south of the starting latitude.
    ##
    ## data = oscur model runs
    ## years = vector of years
    ## type = 'all'; plot all years in a single plot
    ##        'indv'; plot each year in an indivial plot
    ## file = pdf file to save graphic to

    if(!is.null(file) & type == "all")
        pdf(file, width = 14, height = 10)

    if(!is.null(file) & type == "indv")
        pdf(file, width = 6, height = 6)

    if(type == "all")
        par(mfrow = c(7, 7), mar = c(0, 0, 0, 0), oma = c(1, 1, 1, 1))

    if(type == "indv")
        par(mar = c(0, 0, 0, 0), oma = c(1, 1, 1, 1))

    for(j in years) {
        dat.sub <- data[data$year == j, ]
        dat.sub$run.col <- ifelse(dat.sub$end == "south",
            "tomato", "steelblue")
        n.runs  <- length(unique(dat.sub$run))
        runs    <- unique(dat.sub$run)

        plot(1, 1, type = "n",
            xlim = c(-170, -110),
            ylim = c(20, 60),
            ylab = "",
            xlab = "",
            axes = FALSE)
        plot(countriesLow, add = TRUE,
            col = "grey80",
            border = "grey70",
            lwd = 0.5)
        d_ply(dat.sub, .(run),
            function(x) lines(x$lon, x$lat, col = x$run.col, lwd = 0.5))

        text(x = -113, y = 59, labels = paste(j))
        box(col = "grey70")
    }

    if(!is.null(file))
        dev.off()
}



## subset_grid ---------------------------------------------
subset_grid <- function(data,
                        north = 59,
                        south = 35,
                        west = -145,
                        east = -121) {
    ## This function takes as input oscurs model runs and subsets the starting
    ## grid according to the specified coordinates.

    dat1 <- data[data$start.lon >= west, ]
    dat2 <- dat1[dat1$start.lat >= south, ]
    dat3 <- dat2[dat2$start.lon <= east, ]
    dat4 <- dat3[dat3$start.lat <= north, ]
    return(dat4)
}
