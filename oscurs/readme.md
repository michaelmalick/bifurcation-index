There is one script to run the OSCURS model (`oscurs-run.scpt`) and another to
download the data (`oscurs-download.scpt`) from the model runs.

The "run" script simulates drifters using the online web app. Because the
start points for the drifters are not a complete square (fewer start parts at
a given latitude as you go north), the script should be run at all longitudes
for a single latitude. Therefore, the script needs to be run 25 times with
different input latitude (and longitude) values.

The download script will download all simulated data and the number of runs for
the particular set should be updated prior to running.


    n  lat lon min lon max n lon
    -- --- ------- ------- -----
    1   35     215     239    25
    2   36     215     238    24
    3   37     215     237    23
    4   38     215     236    22
    5   39     215     236    22
    6   40     215     235    21
    7   41     215     235    21
    8   42     215     235    21
    9   43     215     235    21
    10  44     215     235    21
    11  45     215     235    21
    12  46     215     235    21
    13  47     215     235    21
    14  48     215     235    21
    15  49     215     234    20
    16  50     215     232    18
    17  51     215     231    17
    18  52     215     228    14
    19  53     215     227    13
    20  54     215     226    12
    21  55     215     226    12
    22  56     215     225    11
    23  57     215     224    10
    24  58     215     223     9
    25  59     215     221     7
    ----------------------------
    total runs for a year = 448
