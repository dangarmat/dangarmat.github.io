---
layout: post
title: Unsupervised Learning About NHL Goalies
category: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
tags: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
excerpt_separator: <!--more-->
---

As a former goalie myself, watching the NHL playoffs, curiousity grew about who are these goalies who are so much better than me they beat me to bring in the NHL? Who's a hero, and who's maybe not a keeper? 

What better way to understand how they shake out than clustering their regular season statisitcs? This is an opportunity to work with [tibbleColumns](https://github.com/nhemerson/tibbleColumns) by Hoyt Emerson, a new package that adds some intriguing functionality to dplyr, and [dendextend](https://cran.r-project.org/package=dendextend) by Tal Gallili, which adds options to heirarchical clustering diagrams. Best data found came from Rob Vollman at [http://www.hockeyabstract.com/testimonials](http://www.hockeyabstract.com/testimonials).


<!--more-->
![Frederick Andersen](/images/640px-Capitals-Maple_Leafs.jpg)
By <a rel="nofollow" class="external text" href="https://www.flickr.com/people/65193799@N00">David</a> from Washington, DC - <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/bootbearwdc/34075134291/">_25A9839</a>, <a href="https://creativecommons.org/licenses/by/2.0" title="Creative Commons Attribution 2.0">CC BY 2.0</a>, <a href="https://commons.wikimedia.org/w/index.php?curid=58534896">Link</a>

## 1. Loading data

What's the data from hockeyabstract look like? Let's load some packages we'll be using in this analysis and take an initial glimpse.

```r
library(tidyverse)
library(readxl)
library(dbscan)
#devtools::install_github("nhemerson/tibbleColumns") # requires new-ish version of R
library(tibbleColumns)
library(GGally)
library(broom)
library(naniar)
library(ggfortify)
library(RColorBrewer)
library(scales)
library(dendextend)
library(viridis)

goalies <- read_excel('NHL Goalies 2017-18.xls', sheet = 'Goalies')
glimpse(goalies)

#Observations: 95
#Variables: 132
#$ X__1         <dbl> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, ...
#$ DOB          <dttm> 1998-09-20, 1982-09-18, 1990-03-02, 1988-01-05, 1988-02-11, 1989-09-16, 1988-09-20...
#$ `Birth City` <chr> "Lantzville", "Banská Bystrica", "Barrie", "Norrtälje", "Surrey", "Lloydminster", "...
#$ `S/P`        <chr> "BC", NA, "ON", NA, "BC", "SK", NA, "VA", "ON", "MI", "MA", NA, "MN", "QC", "NB", "...
#$ Cntry        <chr> "CAN", "SVK", "CAN", "SWE", "CAN", "CAN", "RUS", "USA", "CAN", "USA", "USA", "SWE",...
#$ Nat          <chr> "CAN", "SVK", "CAN", "SWE", "CAN", "CAN", "RUS", "USA", "CAN", "USA", "USA", "SWE",...
#$ Ht           <dbl> 73, 73, 75, 76, 74, 74, 74, 78, 78, 75, 74, 78, 73, 74, 73, 76, 75, 74, 76, 73, 73,...
#$ Wt           <dbl> 189, 196, 202, 187, 215, 211, 182, 232, 220, 173, 195, 229, 182, 180, 200, 200, 195...
#$ Sh           <chr> "L", "L", "R", "L", "L", "L", "L", "L", "L", "L", "L", "L", "R", "L", "L", "L", "L"...
```
At 95 vs. 132, this has fewer players than variables! Can see the first column is just rownumber, so remove it. Then take a look look at the distribution of games.

```r
goalies <- goalies[ , -1]

ggplot(goalies, aes(x = GP)) + 
  geom_histogram()
```
![goalies_03](/images/goalies_03.png)
Fairly uniformly disttributed with a bit fewer as the number of games played (GP) goes up.


Defining a starter as a goalie who plays 35+ regular season games, we can see 39 such starters, more than the number of NHL teams. There are some teams with 2 starters as defined 35+. Are they duplicates? 
```r
goalies %>% 
  filter(GP >= 35) %>% 
  tbl_out('starters') %>%   # tbl_out saves a data frame and allows a pipe to continue
  count()
## A tibble: 1 x 1
#      n
#  <int>
#1    39
  
starters %>% 
  group_by(`Team(s)`) %>% 
  count() %>% 
  arrange(desc(n))
## A tibble: 32 x 2
## Groups:   Team(s) [32]
#   `Team(s)`     n
#   <chr>     <int>
# 1 BUF           2
# 2 CAR           2
# 3 COL           2
# 4 DAL           2
# 5 FLA           2
# 6 NJD           2
# 7 WSH           2
# 8 ANA           1
# 9 ARI           1
#10 BOS           1
## ... with 22 more rows
  
starters %>% 
  group_by(`Team(s)`) %>% 
  count() %>% 
  filter(n == 2) %>% 
  ungroup() %>% 
  left_join(starters, by = 'Team(s)') %>% 
  select(`Team(s)`, `First Name`, `Last Name`)
# don't see any dupes

# make sure no dupes in general
goalies %>% 
  group_by(`Last Name`, `First Name`) %>% 
  count() %>% 
  arrange(desc(n)) 
## A tibble: 95 x 3
## Groups:   Last Name, First Name [95]
#   `Last Name` `First Name`     n
#   <chr>       <chr>        <int>
# 1 Allen       Jake             1
# 2 Andersen    Frederik         1
# 3 Anderson    Craig            1
# 4 Appleby     Ken              1
# 5 Bernier     Jonathan         1
# 6 Berra       Reto             1
# 7 Berube      J-F              1
# 8 Bishop      Ben              1
# 9 Bobrovsky   Sergei           1
#10 Brossoit    Laurent          1
## ... with 85 more rows

goalies %>% 
  select(`Last Name`, `First Name`, GP, `Team(s)`) %>% 
  filter(str_detect(`Team(s)`, ','))
## A tibble: 6 x 4
#  `Last Name` `First Name`    GP `Team(s)`    
#  <chr>       <chr>        <dbl> <chr>        
#1 Lack        Eddie            8 CGY, NJD     
#2 Kuemper     Darcy           29 LAK, ARI     
#3 Montoya     Al              13 MTL, EDM     
#4 Domingue    Louis           19 ARI, TBL     
#5 Mrazek      Petr            39 DET, PHI     
#6 Niemi       Antti           24 PIT, FLA, MTL
```
So no duplicates. Teams can hold more than one team in the field with a comma, as opposed to only showing the last team the gaolie played for in 2018.

Heights of NHL goalies are rediculous these days! Less than 6 feet need not apply, it seems.
```r
goalies %>% 
  mutate(`Height in Feet` = Ht / 12) %>% 
  ggplot(aes(x = `Height in Feet`, y = GP)) + 
  geom_jitter(aes(alpha = .5), width = .01) +
  scale_alpha(guide = FALSE) +
  geom_smooth()
```
![goalies04](/images/goalies04.png)

Who are these *very short* people on the left getting game time?
```r
goalies %>% 
  filter(Ht < 6.0 * 12) %>% 
  select(`First Name`, `Last Name`, Ht, GP, `Team(s)`)
## A tibble: 3 x 5
#  `First Name` `Last Name`    Ht    GP `Team(s)`
#  <chr>        <chr>       <dbl> <dbl> <chr>    
#1 Juuse        Saros          71    26 NSH      
#2 Jaroslav     Halak          71    54 NYI      
#3 Anton        Khudobin       71    31 BOS      

paste0(71 %/% 12, '\'', 71 %% 12, '\'\', what a bunch of short people!')
# [1] "5'11'', what a bunch of short people!"
```
5 foot 11 inches, well, as a bit shorter, now I finally know the *primary* reason I'm not in the NHL!

## 2. Simpler Clustering
