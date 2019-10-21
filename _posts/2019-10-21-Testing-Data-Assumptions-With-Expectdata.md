---
layout: post
title: Checking data against expectations in a data preparation pipeline with expectdata 
date:   2019-10-21 10:42:53
category: [R, expectdata, expect_data, pipeline, data engineering]
tags: [R, expectdata, expect_data, pipeline, data engineering]
excerpt_separator: <!--more-->
---

Expectdata is an R package that makes it easy to check assumptions about a data frame before conducting analyses. Below is a concise tour of some of the data assumptions expectdata can test for you. For example:

![](https://dgarmat.github.io/images/example_expect_fail_20191021.png)

<!--more-->

Check for unexpected duplication
--------------------------------

``` r
library(expectdata)
expect_no_duplicates(mtcars, "cyl")
#> [1] "top duplicates..."
#> # A tibble: 3 x 2
#> # Groups:   cyl [3]
#>     cyl     n
#>   <dbl> <int>
#> 1     8    14
#> 2     4    11
#> 3     6     7
#> Error: Duplicates detected in column: cyl
```

The default `return_df == TRUE` option allows for using these function as part of a dplyr piped expression that is stopped when data assumptions are not kept.

``` r
library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
mtcars %>% 
  filter(cyl == 4) %>% 
  expect_no_duplicates("wt", return_df = TRUE) %>% 
  ggplot(aes(x = wt, y = hp, color = mpg, size = mpg)) +
  geom_point()
#> [1] "no wt duplicates...OK"
```

![](https://dgarmat.github.io/images/no_dupes_20191021.png)

If there are no expectations violated, an "OK" message is printed.

After joining two data sets you may want to verify that no unintended duplication occurred. Expectdata allows comparing pre- and post- processing to ensure they have the same number of rows before continuing.

``` r
expect_same_number_of_rows(mtcars, mtcars, return_df = FALSE)
#> [1] "Same number of rows...OK"
expect_same_number_of_rows(mtcars, iris, show_fails = FALSE, stop_if_fail = FALSE, return_df = FALSE)
#> Warning: Different number of rows: 32 vs: 150

# can also compare to no df2 to check is zero rows
expect_same_number_of_rows(mtcars, show_fails = FALSE, stop_if_fail = FALSE, return_df = FALSE) 
#> Warning: Different number of rows: 32 vs: 0
```

Can see how the `stop_if_fail = FALSE` option will turn failed expectations into warnings instead of errors.

Check for existance of problematic rows
---------------------------------------

Comparing a data frame to an empty, zero-length data frame can also be done more explicitly. If the expectations fail, cases can be shown to begin the next step of exploring why these showed up.

``` r
expect_zero_rows(mtcars[mtcars$cyl == 0, ], return_df = TRUE)
#> [1] "No rows found as expected...OK"
#>  [1] mpg  cyl  disp hp   drat wt   qsec vs   am   gear carb
#> <0 rows> (or 0-length row.names)
expect_zero_rows(mtcars$cyl[mtcars$cyl == 0])
#> [1] "No rows found as expected...OK"
#> numeric(0)
expect_zero_rows(mtcars, show_fails = TRUE)
#>                    mpg cyl disp  hp drat    wt  qsec vs am gear carb
#> Mazda RX4         21.0   6  160 110 3.90 2.620 16.46  0  1    4    4
#> Mazda RX4 Wag     21.0   6  160 110 3.90 2.875 17.02  0  1    4    4
#> Datsun 710        22.8   4  108  93 3.85 2.320 18.61  1  1    4    1
#> Hornet 4 Drive    21.4   6  258 110 3.08 3.215 19.44  1  0    3    1
#> Hornet Sportabout 18.7   8  360 175 3.15 3.440 17.02  0  0    3    2
#> Valiant           18.1   6  225 105 2.76 3.460 20.22  1  0    3    1
#> Error: Different number of rows: 32 vs: 0
```

This works well at the end of a pipeline that starts with a data frame, runs some logic to filter to cases that should not exist, then runs `expect_zero_rows()` to check no cases exist.

``` r
# verify no cars have zero cylindars
mtcars %>% 
  filter(cyl == 0) %>% 
  expect_zero_rows(return_df = FALSE)
#> [1] "No rows found as expected...OK"
```

Can also check for NAs in a vector, specific columns of a data frame, or a whole data frame.

``` r
expect_no_nas(mtcars, "cyl", return_df = FALSE)
#> [1] "Detected 0 NAs...OK"
expect_no_nas(mtcars, return_df = FALSE)
#> [1] "Detected 0 NAs...OK"
expect_no_nas(c(0, 3, 4, 5))
#> [1] "Detected 0 NAs...OK"
#> [1] 0 3 4 5
expect_no_nas(c(0, 3, NA, 5))
#> Error: Detected 1 NAs
```

Several in one dplyr pipe expression:

``` r
mtcars %>% 
  expect_no_nas(return_df = TRUE) %>% 
  expect_no_duplicates("wt", stop_if_fail = FALSE) %>% 
  filter(cyl == 4) %>% 
  expect_zero_rows(show_fails = TRUE)
#> [1] "Detected 0 NAs...OK"
#> [1] "top duplicates..."
#> # A tibble: 2 x 2
#> # Groups:   wt [2]
#>      wt     n
#>   <dbl> <int>
#> 1  3.44     3
#> 2  3.57     2
#> Warning: Duplicates detected in column: wt
#>    mpg cyl  disp hp drat    wt  qsec vs am gear carb
#> 1 22.8   4 108.0 93 3.85 2.320 18.61  1  1    4    1
#> 2 24.4   4 146.7 62 3.69 3.190 20.00  1  0    4    2
#> 3 22.8   4 140.8 95 3.92 3.150 22.90  1  0    4    2
#> 4 32.4   4  78.7 66 4.08 2.200 19.47  1  1    4    1
#> 5 30.4   4  75.7 52 4.93 1.615 18.52  1  1    4    2
#> 6 33.9   4  71.1 65 4.22 1.835 19.90  1  1    4    1
#> Error: Different number of rows: 11 vs: 0
```
