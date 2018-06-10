---
layout: post
title: Unsupervised Learning About NHL Goalies
category: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
tags: [clustering, unsupervised learning, tibbleColumns, hockey, dendExtend]
excerpt_separator: <!--more-->
---

As a former goalie myself, watching the NHL playoffs, curiousity grew about who are these goalies who are so much better than me I'm not in the NHL but they are? Who's a hero, and who's maybe not a keeper? 

What better way to understand how they shake out than clustering their regular season statisitcs? This is an opportunity to work with [tibbleColumns](https://github.com/nhemerson/tibbleColumns) by Hoyt Emerson, a new package that adds some intriguing functionality to dplyr, and [dendextend](https://cran.r-project.org/package=dendextend) by Tal Gallili, which adds options to heirarchical clustering diagrams. Best data I found came from Rob Vollman at [http://www.hockeyabstract.com/testimonials](http://www.hockeyabstract.com/testimonials).


<!--more-->
By <a rel="nofollow" class="external text" href="https://www.flickr.com/people/65193799@N00">David</a> from Washington, DC - <a rel="nofollow" class="external text" href="https://www.flickr.com/photos/bootbearwdc/34075134291/">_25A9839</a>, <a href="https://creativecommons.org/licenses/by/2.0" title="Creative Commons Attribution 2.0">CC BY 2.0</a>, <a href="https://commons.wikimedia.org/w/index.php?curid=58534896">Link</a>

## 1. Loading data

What's the data from hockeyabstract look like? Let's load some packages we'll be using in this analysis and take an initial glimpse.

```r
library(tidyverse)
library(readxl)
library(dbscan)
devtools::install_github("nhemerson/tibbleColumns") # requires new-ish version of R
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
![goalies_02](/images/goalies_02.PNG)

At 95, fewer players than variables! Can see the first column is just rownumber, so remove it. Then take a look look at the distribution of games.

```r
goalies <- goalies[ , -1]

ggplot(goalies, aes(x = GP)) + 
  geom_histogram()

goalies %>% 
  filter(GP >= 35) %>% 
  tbl_out('starters') %>% 
  count()

goalies <- goalies[ , -1]


# take a look at distribution of games

ggplot(goalies, aes(x = GP)) + 
  geom_histogram()
```
![goalies_03](/images/goalies_03.png)

Some at low numbers, and a bit fewer as the number of games played goes up.


```r
goalies %>% 
  filter(GP >= 35) %>% 
  tbl_out('starters') %>% 
  count()
  
starters %>% 
  group_by(`Team(s)`) %>% 
  count() %>% 
  arrange(desc(n))
  
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
```


