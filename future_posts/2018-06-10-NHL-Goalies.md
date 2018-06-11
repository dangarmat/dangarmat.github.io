---
layout: post
title: Unsupervised Learning About NHL Goalies
category: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
tags: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
excerpt_separator: <!--more-->
---

As a former goalie myself, watching the NHL playoffs, curiousity grew about who are these goalies who are so much better than me they beat me to bring in the NHL? Who's a hero, and who's maybe not a keeper? 

What better way to understand how they shake out than clustering their regular season statisitcs? This is an opportunity to work with [tibbleColumns](https://github.com/nhemerson/tibbleColumns) by Hoyt Emerson, a new package that adds some intriguing functionality to dplyr, and [dendextend](https://cran.r-project.org/package=dendextend) by Tal Gallili, which adds options to heirarchical clustering diagrams. Best data found came from Rob Vollman at [http://www.hockeyabstract.com/testimonials](http://www.hockeyabstract.com/testimonials).

![Frederick Andersen](/images/640px-Capitals-Maple_Leafs.jpg)

<!--more-->
By <a rel="nofollow" class="external text" href="https://www.flickr.com/people/65193799@N00">David</a> from Washington, DC - <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/bootbearwdc/34075134291/">_25A9839</a>, <a href="https://creativecommons.org/licenses/by/2.0" title="Creative Commons Attribution 2.0">CC BY 2.0</a>, <a href="https://commons.wikimedia.org/w/index.php?curid=58534896">Link</a>

## 1. Loading data

How does the hockeyabstract data look? Let's load some packages we'll be using in this analysis and take an initial glimpse.

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
At 95 by 132 this has fewer players than variables! Can see the first column is just rownumber, so remove it. Then take a look look at the distribution of games.

### 1.1. Distribution of Games Played (GP)

```r
goalies <- goalies[ , -1]

ggplot(goalies, aes(x = GP)) + 
  geom_histogram()
```
![goalies_03](/images/goalies_03.png)

Fairly uniformly disttributed with a bit fewer as the number of games played (GP) goes up.


Defining a starter as a goalie who plays 35+ regular season games, we can see 39 such starters, more than 31, the number of NHL teams. There are some teams with 2 starters as defined 35+. Are they duplicates? 
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

### 1.2. Distribution of Heights

Heights of NHL goalies are rediculous these days! 
```r
goalies %>% 
  mutate(`Height in Feet` = Ht / 12) %>% 
  ggplot(aes(x = `Height in Feet`, y = GP)) + 
  geom_jitter(aes(alpha = .5), width = .01) +
  scale_alpha(guide = FALSE) +
  geom_smooth()
```
![goalies04](/images/goalies04.png)

Less than 6 feet need not apply, it seems.

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

## 2. Initial Clustering
Let's start with something simple. 

### 2.1. k = 2
Since we've looked at Games Played and Height, let's add key statistic, Save Percentage and k-means it with k = 2.

```r
clusters_HGS <- goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  kmeans(centers = 2)
# Error in do_one(nmeth) : NA/NaN/Inf in foreign function call (arg 1)

# we have some NAs
goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  is.na() %>% 
  sum()
#[1] 1

# Just 1, who is it?
goalies[is.na(goalies$Ht), ] %>% 
  select(`Last Name`, `First Name`, GP, Ht, `SV%`)
#  `Last Name` `First Name`    GP    Ht `SV%`
#  <chr>       <chr>        <dbl> <dbl> <dbl>
#1 Foster      Scott            1    NA     1
```
R's `kmeans()` returns an error because of an `NA`. Who is this `NA`? Scott Foster. Chicago accountant, Scott Foster, may be the most famous modern NHL goalie to play 1 game. Classy hockeyabstract added him, [looks like his height is 6'0''](https://en.wikipedia.org/wiki/Scott_Foster_(ice_hockey)) so we'll add it.

```r
goalies[is.na(goalies$Ht), 'Ht'] <- 6 * 12

# try again
clusters_HGS <- goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  kmeans(centers = 2, nstart = 100)

goalies$cluster_2 <- factor(clusters_HGS$cluster)

goalies %>% 
  select(Ht, GP, `SV%`, cluster_2) %>% 
  ggpairs(aes(color = cluster_2, alpha = 0.4))
```
![goalies05](/images/goalies05.png)

Looking along the diagonal, it looks like clustering split almost entirely along Games Played. This suggests distinction between backup and starter may be the strongest distinction in these three fields of data. Out of curiosity, what value of GP does that split suggest is a good cutoff for a starter? 
```r
goalies %>% 
  group_by(cluster_2) %>% 
  summarise(min(GP), max(GP))
## A tibble: 2 x 3
#  cluster_2 `min(GP)` `max(GP)`
#  <fct>         <dbl>     <dbl>
#1 1                 1        32
#2 2                35        67
```
Between 32 GP and 35 GP a goalie becomes a starter - would be a fair rule of thumb for 2017-2018's NHL regular season.

### Better k than k = 2?
Do these three fields present more than 2 clusters? Using a scree plot to see how much remaining variance additional clusters fail to capture, we see k of 2 and debatably 3 are "elbows" meaning good numbers for these data.
```r
wssplot <- function(df, nc = 15, seed = 1234, nstart = 1){
  wss <- (nrow(df) - 1) * sum(apply(df, 2, var))
  for (i in 2:nc){
    set.seed(seed)
    wss[i] <- sum(kmeans(df, centers = i, nstart = nstart)$withinss)}
  qplot(x = 1:nc, y = wss,  xlab="Number of Clusters",
        ylab="Within groups sum of squares") + geom_line() +
    theme(axis.title.y = element_text(size = rel(.8), angle = 90)) +
    theme(axis.title.x = element_text(size = rel(.8), angle = 00)) +
    theme(axis.text.x = element_text(size = rel(.8))) +
    theme(axis.text.y = element_text(size = rel(.8)))
}

goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  wssplot(nstart = 100)
```
![goalies06](/images/goalies06.png)

Importantly, though, these data aren't scaled. Scaling and centering, also known as normalizing better removes effects of units. For example are changes or ten degrees celsius equally as dramatic as ten degrees farenheight? No! So let's scale these are retry a scree plot.

```r
# so what if we scale it?
goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  scale() %>% 
  tibble_out('scaled_3_vars') %>% 
  wssplot(nstart = 100)
# looks like 4
```
![goalies07](/images/goalies07.png)

Now it looks like an elbow in remaining unexplained variance at k = 4 clusters.

So rerunning the pairs plot on the scaled 3 variables:
```r
set.seed(1001) # so cluster assignments stay the same
scaled_3_vars %>% 
  do(clusters_HGS_scaled = kmeans(., centers = 4, nstart = 1000)) %>% 
  tbl_module((.$clusters_HGS_scaled[[1]]$centers), 'scaled_centers') %>% 
  do(augment(.$clusters_HGS_scaled[[1]], scaled_3_vars)) %>% 
  select('cluster_scaled' = `.cluster`) %>% 
  bind_cols(goalies) %>% 
  tibble_out('goalies') %>% 
  select(Ht, GP, `SV%`, cluster_scaled) %>% 
  ggpairs(aes(color = cluster_scaled, alpha = 0.4))
```
![goalies08](/images/goalies08.png)

Ht vs GP shows some good separation. Save Percentage (SV%) doesn't do much except to separate out 1 "really bad" showing, a goalie who had 50% SV%. I'm not saying, as a sub- 5'11'' individual I could do better, but who is that?

```r
goalies %>% 
  filter(cluster_scaled == 3) %>% 
  select(`First Name`, `Last Name`, GP, Ht, `SV%`, cluster_scaled, SA, MIN)
```
[Dylan Ferguson](https://www.nhl.com/goldenknights/news/a-chat-with-dylan-ferguson/c-293023078) apparently had 2 shows against (SA) in 554 minutes, either amazing defense, or it's seconds. Wikipedia verifies he played a little over 9 minutes, or 554 / 60. Will let hockeyabstract know! Let's fix it, anyway.

```r
goalies <- mutate(goalies, MIN = MIN / 60)
```

### 2.3. Prototypical Members
Who are the prototypical members of the cluster? That is, who is closest to the centroid?. Algorithmically, for each center, for each player, we need to calculate total euclidean distance to each center then return the row with the lowest distance to each center.

```r
vars <- colnames(scaled_3_vars)
distances <- map(1:4, ~ rowSums(abs(scaled_3_vars[ , vars] - 
      as.data.frame(t(scaled_centers[.x, vars]))
       [rep(1, each = nrow(scaled_3_vars)),] )))
# this gives you 4 lists, 1 per cluster
# for each cluster of distances, which player is the min?
prototype_player_nums <- map(1:4, ~ which.min(distances[[.x]]))

# for each prototype, who is it?
prototypes <- map_df(1:4, ~ goalies[prototype_player_nums[[.x]], c('cluster_scaled', 'First Name', 'Last Name', vars, 'Team(s)')])


# and now plot them on the ggplairs to understand
pm <- goalies %>% 
  select(Ht, GP, `SV%`, cluster_scaled) %>% 
  ggpairs(aes(color = cluster_scaled, alpha = 0.4), 
          columns = vars)

# so which plots need adjusting from default to add prototypes?
# which plots to add points?
sps <- list(pm[2,1], pm[3,1], pm[3,2])
sps2 <- map(1:length(sps), ~ sps[[.x]] + geom_point(data = prototypes, size = 3, color = 1, alpha = .5) + geom_text(data = prototypes, aes(label = paste0(`First Name`, " ", `Last Name`)), color = 1, vjust = -0.5, size = 3, alpha = .5))
pm[2,1] <- sps2[[1]]
pm[3,1] <- sps2[[2]]
pm[3,2] <- sps2[[3]]
pm
```
![goalies09](/images/goalies09.png)

What do these four clusters suggests by the data teach us about these data? Looking at the scatterplot with the best separation, row 2, column 1, we can see the red group in the top-right corner of the plot, represented by Tukka Rask, are mostly starters and taller than average. Backups, in the lower half of the plot can be "short" (purple) or tall (green). Then there's the 50% save percentage group.

## 3. Clustering on All Data
OK let's add in the numbers. Ignoring categorical data for now, which columns are numeric?

```r
goalies %>% 
  map_lgl(is.numeric) %>% 
  mean()
#[1] 0.8120301
```
81% of columns are numeric. Let's save just those.

```
goalies[, map_lgl(goalies, is.numeric)] %>% 
  tibble_out('goalies_stats') %>% 
  glimpse()
#Observations: 95
Variables: 108
$ Ht          <dbl> 73, 73, 75, 76, 74, 74, 74, 78, 78, 75, 74, 78, 73, 74, 73, 76, 75, 7...
#$ Wt          <dbl> 189, 196, 202, 187, 215, 211, 182, 232, 220, 173, 195, 229, 182, 180,...
#$ `Dft Yr`    <dbl> 2017, 2001, 2008, NA, NA, 2008, NA, 2007, NA, 1999, NA, 2009, NA, 200...
#...
#$ MIN__1      <dbl> 9, 20144, 5414, 7996, 3092, 20678, 22814, 6557, 1092, 42926, 7073, 57...
#$ QS__2       <dbl> 0, 117, 41, 62, 33, 211, 229, 54, 6, 338, 56, 38, 12, 319, 38, 134, 4...
#$ RBS__1      <dbl> 0, 41, 12, 22, 5, 45, 46, 13, 8, 72, 22, 16, 5, 78, 13, 27, 13, 7, 26...
#$ GPS__1      <dbl> -0.1, 50.7, 14.3, 20.5, 10.8, 68.2, 77.7, 17.9, 1.1, 143.4, 17.4, 15....
```
These last 13 __ columns are all career stats. They make Henrik Lundqvist look the best if included in this year's numbers. Honestly, didn't even see this until trying to figure out why he looked the best in these numbers but not in any obvious stats posted at nhl.com. 

We could leave them in for some questions, but since ours is limited to 2017-2018 regular season performance, results are more interpritable if we take these 13 __ columns out.
```r
goalies_stats[ , c((108-12):108)]
goalies_stats <- goalies_stats[ , -c((108-12):108)]
```
This leaves 108 numeric columns. How many clusters are there in these 108 variables?
```r
goalies_stats %>% 
  scale() %>% 
  tibble_out('scaled_all_vars') %>% 
  wssplot(nstart = 100)
# Error in do_one(nmeth) : NA/NaN/Inf in foreign function call (arg 1) 
```
We have more `NA`s. Let's take a look at missingness.

```r
vis_miss(goalies_stats)
```

It looks like only a handful of variables have issues. Which are they?
![goalies10](/images/goalies10.png)

```r
sort(unlist(lapply(goalies_stats, function(x) sum(is.na(x)))))
#     SO__1    PIM__1    MIN__1     QS__2    RBS__1    GPS__1        Wt     StMin      StSV 
#        0         0         0         0         0         0         1         5         5 
#     StGA     QS__1       RBS      Pull    Dft Yr        Rd      Ovrl      Ginj      CHIP 
#        5         5         5         5        21        21        21        44        44 
> 
```
Looks like CHIP (Cap Hit of Injured Player) and Ginj (Games Injured), as well as some Draft variables. Are those players who haven't had an injury or been drafted?

```r
table(goalies_stats$Ginj)
#
# 1  2  3  4  5  6  8  9 11 12 13 14 15 31 32 36 
# 6  4  1 26  2  1  1  1  1  1  2  1  1  1  1  1 

table(goalies_stats$CHIP)
#
#  7  11  18  21  45  51  61  88  91 110 171 195 207 265 282 285 299 305 317 400 469 483 545 
#  1   1   1   1   1   1   1   1   1   1   1  26   1   1   1   1   1   1   1   1   1   1   1 
#551 735 988 
#  1   1   1 

goalies_stats$Ginj[is.na(goalies_stats$Ginj)] <- 0
goalies_stats$CHIP[is.na(goalies_stats$CHIP)] <- 0
```
There are no zeros. So going to assume NA implies 0 on these injury variables.


What do we do about draft stats? We could MICE them, but I'm OK with dropping them to get somewhere with what we have more quickly.
```r
goalies_stats <- goalies_stats[ , -which(names(goalies_stats) %in% c('Dft Yr', 'Rd', 'Ovrl'))]
```

Who are the `NA`s for PULL?
```r
goalies_stats %>% 
  filter(is.na(Pull)) %>% 
  select(GP)
## A tibble: 5 x 1
#     GP
#  <dbl>
#1     1
#2     1
#3     1
#4     1
#5     1

goalies_stats$Pull[is.na(goalies_stats$Pull)] <- 0
```
They all played one game. So we'll set NA as 0 pulls.

RBS (Really Bad Starts, stopped less than 85% of shots) `NA`s also correspond to 1 gamers, so probably safe to set `NA`s as 0.
```r
goalies_stats %>% 
  filter(is.na(RBS)) %>% 
  select(GP)
## A tibble: 5 x 1
#     GP
#  <dbl>
#1     1
#2     1
#3     1
#4     1
#5     1

goalies_stats$RBS[is.na(goalies_stats$RBS)] <- 0
```

Who's missing on Wt?
```r
goalies %>% 
  filter(is.na(Wt)) %>% 
  select(`First Name`, `Last Name`)
## A tibble: 1 x 2
#  `First Name` `Last Name`
#  <chr>        <chr>      
#1 Scott        Foster   

goalies_stats$Wt[is.na(goalies_stats$Wt)] <- 185
```
His weight is on Wikipedia (may be the only accountant whose weight is on wikipedia).

All the remaining `NA`s correspond to one game players, so setting them as 0s then hopefully ready to retry the screeplot.
```
goalies_stats <- goalies_stats %>% 
  mutate_all(funs(replace(., is.na(.), 0)))

sum(is.na(goalies_stats))
#[1] 0

goalies_stats %>% 
  scale() %>% 
  tibble_out('scaled_all_vars') %>% 
  wssplot(nstart = 100)
# Error in do_one(nmeth) : NA/NaN/Inf in foreign function call (arg 1) 

sum(is.na(scaled_all_vars)) # more NAs!
#[1] 190

vis_miss(scaled_all_vars)
```
![goalies11](/images/goalies11.png)

Scaling introduced new `NA`s, all in two variables:
```r
sort(unlist(lapply(scaled_all_vars, function(x) sum(is.na(x)))))
#   MIN__1     QS__2    RBS__1    GPS__1         T         G 
#        0         0         0         0        95        95 
```
G is goals. No one scored this year, so no variation, so can remove it for clustering purposes. T?
```r
table(goalies$T)
#
# 0 
#95 
```
I don't know what it is, it's not in the legend, so removing it.

```r
scaled_all_vars <- scaled_all_vars[ , -which(names(scaled_all_vars) %in% c('G', 'T'))]

# Verify variance is uniform
plot(sapply(scaled_all_vars, var))
```
![goalies12](/images/goalies12.png)

Can see here scaling has made all variances 1 for all variables, so ready to do unitless clustering. 
```r
scaled_all_vars %>% 
  wssplot(nstart = 1000)
```
![goalies15](/images/goalies15.png)

An elbow exists at 2 clusters but with potentially correllated variables, we would probably want to go further out to get at more variation explained. 

### 3.2. Principal Component Analysis (PCA)

Another way to simplify this problem is to use principal components to remake the many variables into a smaller subset of linear combinations of variables. If going to use principal components, how many PC do we want?

```r
pc <- princomp(scaled_all_vars)
#Error in princomp.default(scaled_all_vars) : 
#  'princomp' can only be used with more units than variables
## oh darn, there is one that can do it
set.seed(1001)
pc <- prcomp(scaled_all_vars)

plot(pc, type='l')
```
![goalies13](/images/goalies13.png)

Suprisingly almost all the variation is in the first two principal components. Digging into these two big variance explainers, 
```r
autoplot(prcomp(scaled_all_vars), data = scaled_all_vars,
         loadings = TRUE, loadings.colour = 'blue',
         loadings.label = TRUE, loadings.label.size = 3)
```
![goalies14](/images/goalies14.png)
 
It's obvious from the concentration of red to the mid-left, a ton of really highly correllated variables are driving PC1. Investigating the top variables in PC1 using rotation shows it makes sense they're correllated:
```r
sort(pc$rotation[ ,1])
#           SV            SA         SA__1            FA            CA          StSV 
#-0.1333212014 -0.1332894550 -0.1332883575 -0.1331752091 -0.1331230573 -0.1330910681 
#          MIN          EVSA            GP            GS         StMin           NZS 
#-0.1330764843 -0.1330567787 -0.1330433880 -0.1329948485 -0.1329059764 -0.1328682726 
#         LowS            SF           DZS           xGA            FF            CF 
#-0.1327199053 -0.1326864076 -0.1326642460 -0.1326458089 -0.1325894382 -0.1323928423 
#         MedS           OZS           SCA          HDCA           SCF          HDCF 
#-0.1321767984 -0.1320149835 -0.1318439718 -0.1318439718 -0.1317324552 -0.1316340730 
#        HighS          StGA         PP SA         QS__1            GA         GA__1 
#-0.1313239811 -0.1307060961 -0.1306665694 -0.1305825693 -0.1305314242 -0.1305314242 
```
These are factors like Saves, Shots Against, Faced Shot Attempts, Minutes, and all the variations on those like even strength shots against. Basically there is less variation among goalies in these statisitics than the number of variables might suggest at first glance. This implies our intuition of what separates these data at finer distinctions may be found in higher principal components. That also suggest exploring heirarchical clustering, which we will do later. 

We can get to 85% variation explained reducing these 108 variables to 9 principal components so we'll use 9.

```r
summary(pc)

#Importance of components:
#                          PC1     PC2     PC3     PC4     PC5     PC6     PC7     PC8     PC9
#Standard deviation     7.3873 2.90496 2.64554 2.32238 1.90636 1.78026 1.50032 1.43359 1.33277
#Proportion of Variance 0.5298 0.08193 0.06795 0.05236 0.03528 0.03077 0.02185 0.01995 0.01725
#Cumulative Proportion  0.5298 0.61175 0.67970 0.73207 0.76735 0.79812 0.81998 0.83993 0.85717

comp <- data.frame(pc$x[,1:9])
k <- comp %>% 
  kmeans(4, nstart = 10000, iter.max = 1000)
palette(alpha(brewer.pal(9,'Set1'), 0.5))
plot(comp, col=k$clust, pch=16)
```
![goalies16](/images/goalies16.png)

Trying to look at all 9 PCs, can see some good separation at the top-left scatter plots, and much more mixing as we move towards the bottom and right. This plot has four clustered colors to try to make sense of it a bit. Let's say we have four groups, who are these?

```r
goalies$pca_cluster_4 <- factor(k$cluster)
goalies <- goalies %>% 
  bind_cols(comp)

vars <- colnames(comp)
distances <- map(1:4, ~ rowSums(abs(comp[ , vars] - 
                    as.data.frame(t(k$centers[.x, vars]))
                    [rep(1, each = nrow(comp)),] )))
# this gives you 4 lists, 1 per cluster
# for each cluster of distances, which player is the min?
prototype_player_nums <- map(1:4, ~ which.min(distances[[.x]]))
# for each prototype, who is it?
prototypes <- map_df(1:4, ~ goalies[prototype_player_nums[[.x]], c('pca_cluster_4', 'First Name', 'Last Name', 'Team(s)', vars)])

prototypes 
## A tibble: 4 x 13
#  pca_cluster_4 `First Name` `Last Name` `Team(s)`     PC1    PC2     PC3       PC4     PC5
#  <fct>         <chr>        <chr>       <chr>       <dbl>  <dbl>   <dbl>     <dbl>   <dbl>
#1 1             Tuukka       Rask        BOS        -9.05  -1.16    0.661   1.21     -0.540
#2 2             Alexandar    Georgiev    NYR         6.75   1.12    1.65    0.00543   1.20 
#3 3             Dylan        Ferguson    VGK        11.4    1.96  -10.0    10.0     -11.3  
#4 4             Darcy        Kuemper     LAK, ARI    0.397  0.763   1.34   -1.31     -1.25 
## ... with 4 more variables: PC6 <dbl>, PC7 <dbl>, PC8 <dbl>, PC9 <dbl>
```
Only Tuukka Rask is still in this list. Let's plot them.

```r
pm <- goalies %>% 
  select(vars, pca_cluster_4) %>% 
  ggpairs(aes(color = pca_cluster_4, alpha = 0.4), 
          columns = vars[1:4])

sps <- list(pm[2,1], pm[3,1], pm[4,1], pm[3,2], pm[4,2], pm[4,3])
sps2 <- map(1:length(sps), ~ sps[[.x]] + geom_point(data = prototypes, size = 3, color = 'black', alpha = .5) + geom_text(data = prototypes, aes(label = paste0(`First Name`, " ", `Last Name`)), color = 'black', vjust = -0.5, size = 3, alpha = .5))
pm[2,1] <- sps2[[1]]
pm[3,1] <- sps2[[2]]
pm[4,1] <- sps2[[3]]
pm[3,2] <- sps2[[4]]
pm[4,2] <- sps2[[5]]
pm[4,3] <- sps2[[6]]
pm
```
![goalies17](/images/goalies17.png)

So what's it picking up?
Tuuka Rask this year was a starting goalie, pretty good save percentage
Anton Forsberg, at 35 games is borderline starter, basically sharing duties
  his save percentage is a bit lower
 Alexandar Georgiev played 10 games
 Dylan Ferguson we know from before as the 9:14 min, 2 shots one goal


 Alex Lyon played 11 games with an OK save percentage
 Brandon Halverson played one game, 13 minutes, and allowed 1 goal on 5 shots

 this has a bit of a rock project no-duh feel to it
 but maybe what's important is that nothing else stands out
 at 4 clusters, you basically have starters, backups,
 small game fill ins
 and 1 game fill ins
 in terms of the stats that are measured
 this tells us something about the 90 numeric variables in our dataset
 it tells us most of the variation is around a ton of highly correllated
 variables
 this makes sense - the better you play, the more games you play,
 the more hots you face, the more saves, the more 5v5 shots,
 the more faceoffs
 basically its telling us something about the limitation of 
 questons these data can answer without
 further feature engineering and
 additional variables
 
## 4. Outliers
One thing we can do is look for outliers

### 4.1. Lowest PC1
