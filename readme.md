# Bifurcation Index

This repository is for updating the "Bifurcation Index" presented in Malick et
al. (2017). The BI indexes the north-south position of the bifurcation of the
North Pacific Current into the northward flowing Alaska Current and the
southward flowing California Current. The BI is calculated from drifter
simulations that are run via the OSCURS model
<https://oceanview.pfeg.noaa.gov/oscurs/>. For each year, a grid of drifters are
simulated in the North Pacific from February 1 to June 30 and the index is
calculated as the percentage of the simulated drifters that ended south of their
starting latitude. Thus, the index is bound between 0 and 1 with higher values
indicating a more northern bifurcation and lower values indicating a more
southern bifurcation.

A downloadable version of the index is available in the `share` directory.

Malick, M.J., et al. 2017. Effects of the North Pacific Current on the
productivity of 163 Pacific salmon stocks. Fisheries Oceanography
26:268--281. <https://doi.org/10.1111/fog.12190>

Land mask used to truncate drifters when they hit land was the GHRSST 1 km land
sea mask downloaded from: <https://www.ghrsst.org/ghrsst-data-services/tools/>
