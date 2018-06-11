# Clustering NHL Goalies
library(tidyverse)
library(readxl)
library(dbscan)
library(devtools)
#devtools::install_github("nhemerson/tibbleColumns")
library(tibbleColumns)
library(GGally)
library(broom)
library(naniar)
library(ggfortify)
library(RColorBrewer)
library(scales)
library(dendextend)
library(viridis)



# start with one year of goalies
# later run rvest to get all years of goalies and bind rows
# see what you got
# can look at goalies by season, or summarize to by game
# can look at goalie-seasons to see time series and plot
# and cluster TS where x is year in NHL
# could do a 1st PC TS or could do a multivatiate TS
# would be cool
goalies <- read_excel('NHL Goalies 2017-18.xls', sheet = 'Goalies')
glimpse(goalies)

# can see first column is just rownumber, remove it
goalies <- goalies[ , -1]


# take a look at distribution of games

ggplot(goalies, aes(x = GP)) + 
  geom_histogram(bins = 10)

goalies %>% 
  filter(GP >= 35) %>% 
  tbl_out('starters') %>% 
  count()

starters %>% 
  group_by(`Team(s)`) %>% 
  count() %>% 
  arrange(desc(n))
# looks like a few teams split goaltending duties
# or else there could be duplication


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
# no dupes 
# I see teams can hold more than one team in the datum


# heights are rediculous!
goalies %>% 
  mutate(`Height in Feet` = Ht / 12) %>% 
  ggplot(aes(x = `Height in Feet`, y = GP)) + 
  geom_jitter(aes(alpha = .5), width = .01) +
  scale_alpha(guide = FALSE) +
  geom_smooth()

# who're the shorty?
goalies %>% 
  filter(Ht < 6.0 * 12) %>% 
  select(`First Name`, `Last Name`, Ht, GP, `Team(s)`)

paste0(71 %/% 12, '\'', 71 %% 12, '\'\', what a bunch of short people!')
# no wonder I'm not in the NHL, now I know why


### OK let's get to clustering ----

# let's start with something simple
# how about Ht, GP, and `SV%`
# k = 2
clusters_HGS <- goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  kmeans(centers = 2)
# we have some NAs
goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  is.na() %>% 
  sum()
# Just 1, who is it?
goalies[is.na(goalies$Ht), ] %>% 
  select(`Last Name`, `First Name`, GP, Ht, `SV%`)
# Scott Foster is the most famous NHL goalie to play 1 game
# https://en.wikipedia.org/wiki/Scott_Foster_(ice_hockey)
# Classy they added him, looks like his height is 6'0'' so we'll add it

goalies[is.na(goalies$Ht), 'Ht'] <- 6 * 12

# try again
clusters_HGS <- goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  kmeans(centers = 2, nstart = 100)

goalies$cluster_2 <- factor(clusters_HGS$cluster)

goalies %>% 
  select(Ht, GP, `SV%`, cluster_2) %>% 
  ggpairs(aes(color = cluster_2, alpha = 0.4))
# looks like it split almost entirely on Games Played
# looks like it basically defines starters as:
goalies %>% 
  group_by(cluster_2) %>% 
  summarise(min(GP), max(GP))
# 35 games

# how many clusters are there?
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
# looks like 2

# so what if we scale it?
goalies %>% 
  select(Ht, GP, `SV%`) %>% 
  scale() %>% 
  tibble_out('scaled_3_vars') %>% 
  wssplot(nstart = 100)
# looks like 4

#clusters_HGS_scaled <- 

set.seed(1001)
scaled_3_vars %>% 
  do(clusters_HGS_scaled = kmeans(., centers = 4, nstart = 1000)) %>% 
  tbl_module((.$clusters_HGS_scaled[[1]]$centers), 'scaled_centers') %>% 
  do(augment(.$clusters_HGS_scaled[[1]], scaled_3_vars)) %>% 
  select('cluster_scaled' = `.cluster`) %>% 
  bind_cols(goalies) %>% 
  tibble_out('goalies') %>% 
  select(Ht, GP, `SV%`, cluster_scaled) %>% 
  ggpairs(aes(color = cluster_scaled, alpha = 0.4))

# it's really height and GP. SV% isn't factoring into these clusters
# SV% only separattes out 1 "really bad" showing, a goalie who 
# had 50% SV%. Who's that?

goalies %>% 
  filter(cluster_scaled == 3) %>% 
  select(`First Name`, `Last Name`, GP, Ht, `SV%`, cluster_scaled, SA, MIN)
# https://www.nhl.com/goldenknights/news/a-chat-with-dylan-ferguson/c-293023078
# it says 554 minutes but I think it's 554 seconds, little over 9 minutes
554 / 60
# will let the stats guy know!
# let's fix it, anyway

goalies <- mutate(goalies, MIN = MIN / 60)

# who are the prototypical members of the cluster?
# who is closest to the centroid?
# for each center, for each player, 
# calculate total euclidean distance to each center
# get the row

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

# so which need adjusting?
# which are two variables?
#2,1
#3,1
#3,2
# for each plot, check if it's 2D
# at least for now, we can do a check if it's a geom_point
#map(1:length(pm$plots), ~ pm$plots[.x][[1]]$mapping)

#class(pm$plots[1][[1]]$layers[[1]]$geom)[1]

#pm$plots[1:3][[1]]

# which plots to add points?

sps <- list(pm[2,1], pm[3,1], pm[3,2])
sps2 <- map(1:length(sps), ~ sps[[.x]] + geom_point(data = prototypes, size = 3, color = 1, alpha = .5) + geom_text(data = prototypes, aes(label = paste0(`First Name`, " ", `Last Name`)), color = 1, vjust = -0.5, size = 3, alpha = .5))
pm[2,1] <- sps2[[1]]
pm[3,1] <- sps2[[2]]
pm[3,2] <- sps2[[3]]
pm

# starters are Tall
# Backups are either "short" or tall
# then there's the 50% save percentage


### OK let's add in the numbers -----

# which columns are numeric?
goalies %>% 
  map_lgl(is.numeric) %>% 
  mean()
# 81% of columns are numeric

# save just those
goalies[, map_lgl(goalies, is.numeric)] %>% 
  tibble_out('goalies_stats') %>% 
  glimpse()

# the last 13 columns are all Career Stats
# They make Henrik Lundqvist look the best if included in
# this year's numbers
# didn't even see it until trying to figure out what he was the best
# take them out!

goalies_stats[ , c((108-12):108)]
goalies_stats <- goalies_stats[ , -c((108-12):108)]


# how many clusters are there in these 108 variables?
goalies_stats %>% 
  scale() %>% 
  tibble_out('scaled_all_vars') %>% 
  wssplot(nstart = 100)
# we have more NAs, let's take a look at missingness

vis_miss(goalies_stats)
# it looks like only a handful have issues
# which ones are they?

sort(unlist(lapply(goalies_stats, function(x) sum(is.na(x)))))
# looks like CHIP and Ginj, as well as some Draft variables
# are those are players who haven't had an injury?

table(goalies_stats$Ginj)
# there's no zero. I'm going to sub it
table(goalies_stats$CHIP)

goalies_stats$Ginj[is.na(goalies_stats$Ginj)] <- 0
goalies_stats$CHIP[is.na(goalies_stats$CHIP)] <- 0

# what do we do about draft stats? I think drop those columns
# we could MICE it, but I'm OK with dropping them
goalies_stats <- goalies_stats[ , -which(names(goalies_stats) %in% c('Dft Yr', 'Rd', 'Ovrl'))]

# who are the NA for PULL?
goalies_stats %>% 
  filter(is.na(Pull)) %>% 
  select(GP)
# they all played one game, we'll set it as 0 pulls
goalies_stats$Pull[is.na(goalies_stats$Pull)] <- 0

# RBS?
goalies_stats %>% 
  filter(is.na(RBS)) %>% 
  select(GP)
goalies_stats$RBS[is.na(goalies_stats$RBS)] <- 0

goalies_stats %>% 
  filter(is.na(QS__1)) %>% 
  select(GP)
# same for all these remainders, except weight


goalies %>% 
  filter(is.na(Wt)) %>% 
  select(`First Name`, `Last Name`)
# his weight is on Wikipedia (may be the only accountant whose weight is on wikipedia)

goalies_stats$Wt[is.na(goalies_stats$Wt)] <- 185

# make the rest 0
goalies_stats <- goalies_stats %>% 
  mutate_all(funs(replace(., is.na(.), 0)))

sum(is.na(goalies_stats))
# alright


# so we have the NAs cleared, let's scale

goalies_stats %>% 
  scale() %>% 
  tibble_out('scaled_all_vars') %>% 
  wssplot(nstart = 100)

sum(is.na(scaled_all_vars)) # more NAs!

vis_miss(scaled_all_vars)
# it's two variables 
sort(unlist(lapply(scaled_all_vars, function(x) sum(is.na(x)))))

# G is goals, no one scored this year, so no variation, can remove
# T ?
table(goalies$T)
# I don't know what it is, it's not in the legend, so removing it

scaled_all_vars <- scaled_all_vars[ , -which(names(scaled_all_vars) %in% c('G', 'T'))]

# Verify variance is uniform
plot(sapply(scaled_all_vars, var))

pc <- princomp(scaled_all_vars)
# oh darn, there is one that can do it
set.seed(1001)
pc <- prcomp(scaled_all_vars)

plot(pc)
plot(pc, type='l')
# but as far as elbow goes it's all in 1 PC
summary(pc)
# we get to 85% with 10 components so we'll use 10

autoplot(prcomp(scaled_all_vars), data = scaled_all_vars,
         loadings = TRUE, loadings.colour = 'blue',
         loadings.label = TRUE, loadings.label.size = 3)
# what's driving PC1 it is a ton of really highly correllated variables

dim(pc$rotation)
sort(pc$rotation[ ,1])
# Shots Against, Saves, Faced Shot Attempts, Minutes
# and all the variations on those like even strength shots against

# I think where it will get interesting is in the higher principal 
# components. 
# this is sounding a bit like a good spot for a 
# heirarchical clustering method. But we'll look at that later

scaled_all_vars %>% 
  wssplot(nstart = 1000)
# I'd say the big elbow is 2 clusters, but we more
# we have too many highly correllated variables to follow the normal rules

comp <- data.frame(pc$x[,1:9])
comp %>%
  wssplot(nstart = 1000)
# looks quite similar

k <- comp %>% 
  kmeans(4, nstart = 10000, iter.max = 1000)
palette(alpha(brewer.pal(9,'Set1'), 0.5))
plot(comp, col=k$clust, pch=16)

goalies$pca_cluster_4 <- factor(k$cluster)
goalies <- goalies %>% 
  bind_cols(comp)

# so let's say we have 4 groups, who are these 4

vars <- colnames(comp)
distances <- map(1:4, ~ rowSums(abs(comp[ , vars] - 
                    as.data.frame(t(k$centers[.x, vars]))
                    [rep(1, each = nrow(comp)),] )))
# this gives you 4 lists, 1 per cluster
# for each cluster of distances, which player is the min?
prototype_player_nums <- map(1:4, ~ which.min(distances[[.x]]))

# for each prototype, who is it?
prototypes <- map_df(1:4, ~ goalies[prototype_player_nums[[.x]], c('pca_cluster_4', 'First Name', 'Last Name', 'Team(s)', vars)])

prototypes # only Tuukka Rask is still in this list

# let's plot them
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


# So what's it picking up?
# Tuuka Rask this year was a starting goalie, pretty good save percentage
# Anton Forsberg, at 35 games is borderline starter, basically sharing duties
#  his save percentage is a bit lower
# Alexandar Georgiev played 10 games
# Dylan Ferguson we know from before as the 9:14 min, 2 shots one goal


# Alex Lyon played 11 games with an OK save percentage
# Brandon Halverson played one game, 13 minutes, and allowed 1 goal on 5 shots

# this has a bit of a rock project no-duh feel to it
# but maybe what's important is that nothing else stands out
# at 4 clusters, you basically have starters, backups,
# small game fill ins
# and 1 game fill ins
# in terms of the stats that are measured
# this tells us something about the 90 numeric variables in our dataset
# it tells us most of the variation is around a ton of highly correllated
# variables
# this makes sense - the better you play, the more games you play,
# the more hots you face, the more saves, the more 5v5 shots,
# the more faceoffs
# basically its telling us something about the limitation of 
# questons these data can answer without
# further feature engineering and
# additional variables

# one thing we can do is look for outliers
# outliers?
#lowest PC1
goalies %>% 
  arrange(desc(PC1)) %>% 
  select(PC1, 'First Name', 'Last Name', 'Team(s)')

# Does that make Frederik Andersen the favorite for the Vezina?
# His stats don't seem that outstanding but
# he did play a lot of games
# would be good to see why he has the best PC1
which(goalies$`Last Name` == 'Andersen')
vars <- names(pc$rotation[ , 1])
Andersen_PC1 <- pc$rotation[vars, 1] * scaled_all_vars[55, vars] %>% 
  t()
sum(Andersen_PC1) # matches

data_frame("Variable" = rownames(Andersen_PC1),
           "Value" = Andersen_PC1[,1]) %>% 
  arrange(desc(abs(Value)))
# SCF = Toronto's scoring chanes
# HDGF = Toronto goals
# HDCF = Toronto goals
# xGA = Expected Goals Against (?)
# HighG = Goals allowed
# actually these are neutral or negative even
# Toronto had a lot of shots against, yet still made the playoffs
# But I wouldn't say Andersen's the front runner for the Vezina
# If we want to know that, it may make more sense to fit a 
# predictive model on previous winners or nominees
# But something very different was happening in his case
# It's not quite clear what, but he's an outlier
# The Leafs had a record year for the franchise, on some stats so could be
# picking that up
# on nhl.com, I can see he did face the most shots this season
# and most saves
# http://www.nhl.com/stats/player?report=goaliesummary&reportType=season&seasonFrom=20172018&seasonTo=20172018&gameType=2&filter=gamesPlayed,gte,1&sort=saves

# who doesn't belong?
goalies %>%
  group_by(pca_cluster_4) %>% 
  top_n(2, GP) %>% 
  arrange(desc(PC1)) %>% 
  select('pca_cluster_4', 'First Name', 'Last Name', 'Team(s)', 'GP', 'SV%', PC1, DOB) %>% 
  tibble_out('up_and_up')
# I think this means these are goalies we might see more of
  
goalies %>%
  group_by(pca_cluster_4) %>% 
  top_n(2, desc(GP)) %>% 
  arrange(desc(PC1)) %>% 
  select('pca_cluster_4', 'First Name', 'Last Name', 'Team(s)', 'GP', 'SV%', PC1, DOB) %>% 
  filter(pca_cluster_4 != 2)%>% 
  tibble_out('down_and_down')
# I think this means these are goalies we might see less of

goalies %>% 
  ggplot(aes(x = `GP`, y = `SV%`, color = pca_cluster_4)) +
  geom_point() +
  scale_y_continuous(limits = c(0.85, 0.95)) +
  scale_x_continuous(limits = c(0, 68)) +
  geom_text(data = up_and_up, aes(label = paste0(`First Name`, " ", `Last Name`)), color = 'darkgreen', vjust = -0.5, size = 3, alpha = .5) +
  geom_text(data = down_and_down, aes(label = paste0(`First Name`, " ", `Last Name`)), color = 'darkred', vjust = -0.5, size = 3, alpha = .5)

# This shows how games played explains most of the variation in stats
# might want to look at per game stats


# I think I really want to do some heirarchical clustering on this
# and see what's going on at the deeper level.

# let's use some of the previous work to add names of goalies we saw before
# this will help get an intuition of the clustering going on
key_goalies <- goalies[85 ,] %>% 
  bind_rows(prototypes) %>% 
  bind_rows(up_and_up) %>% 
  bind_rows(down_and_down) %>% 
  group_by(`First Name`, `Last Name`) %>% 
  count() %>% 
  ungroup %>% 
  mutate(goalie = paste0(`First Name`, " ", `Last Name`)) %>%
  select(goalie) %>% 
  bind_rows()

# take the list and if the player's name is in this list
# return their name, otherwise return their rownumber

goalies$name <- paste0(goalies$`First Name`, " ", goalies$`Last Name`)
goalies$playernumber <- 1:nrow(goalies)

rownames(scaled_all_vars) <- ifelse(goalies$name %in% key_goalies$goalie,
                                    goalies$`Last Name`,
                                    goalies$playernumber)
  
dist_matrix <- dist(scaled_all_vars) 
#colnames(dist_matrix) <- goalies$`Last Name`
hc_goalies_sc_avg <- hclust(dist_matrix, method="average")

# loop on this
linkages_to_example <- c("average", "single", "complete",  
                         "ward.D2", "median", "centroid")


create_dend <- function(linkage = "ward.D2", dist_matrix){
  dist_matrix %>% 
    hclust(method = linkage) %>% 
    as.dendrogram() 
}

plot_dend <- function(linkage = "ward.D2", dist_matrix){
  dist_matrix %>% 
    hclust(method = linkage) %>% 
    as.dendrogram() %>% 
    highlight_branches_col() %>% 
    plot(main = paste0(linkage, " linkage"))
}

dends <- map(linkages_to_example, create_dend, dist_matrix = dist_matrix)

par(mfrow = c(2, 3));
walk(.x = linkages_to_example, plot_dend, dist_matrix = dist_matrix);
par(mfrow = c(1, 1))

# Ward.D2 shows why k-means picked up 2-3 clusters really. You have the starters and backup, then you have
# backups with several games, fulltime backups
# and parttime backups up from the minors
# I'd bet

# ward.D2 is the Ward's method


col_vec <- ifelse(labels(dends[[4]]) %in% prototypes$`Last Name`,
       "black",
       ifelse(labels(dends[[4]]) %in% up_and_up$`Last Name`,
              "darkgreen",
              ifelse(labels(dends[[4]]) %in% down_and_down$`Last Name`,
                     "darkred",
                     "grey")
       )
)



dend1 <- dends[[4]] %>% 
  set("labels_col", col_vec) %>% 
  set("branches_k_color", k = 3) %>%
  #hang.dendrogram %>%
  plot(main = "Ward.D2 linkage")

# would like to add the grouping boxes
the_bars <- cbind(cutree(dends[[4]], k = 3, order_clusters_as_data = FALSE),
                  cutree(dends[[4]], k = 5, order_clusters_as_data = FALSE))
colored_bars(colors = the_bars, dend = dends[[4]])
# but doesn't work 

#Maybe just look at the starters
labels(dends[[4]])
clusters <- cutree(dends[[4]], k = 3, order_clusters_as_data = FALSE)
clusters <- clusters[clusters %in% c(1,2)]


scaled_all_vars2 <- scaled_all_vars
rownames(scaled_all_vars2) <- paste0(substr(goalies$`First Name`, 1,1), ". " ,goalies$`Last Name`)

starters <- scaled_all_vars2 %>% 
  dist() %>% 
  hclust(method = "ward.D2") 

clusters <- cutree(starters, k = 3, order_clusters_as_data = FALSE)
clusters <- clusters[clusters %in% c(1,2)]

starters %>%  
  as.dendrogram() %>% 
  prune(names(clusters)) %>% 
  #set("labels_col", col_vec) %>% 
  set("branches_k_color", k = 3) %>%
  #hang.dendrogram %>%
  plot(main = "ward.D2 linkage")

# these are your three premier NHL goalie groups, I think
# I feel like group 1 has all the Vezina-possible goalies this year
# It'd be good to take this group and see what they look like
# in PCs

clusters <- cutree(starters, h = 13, order_clusters_as_data = FALSE)
clusters <- clusters[clusters %in% c(10:12)]

starters_to_examine <- goalies[paste0(substr(goalies$`First Name`, 1,1), ". " ,goalies$`Last Name`) %in% names(clusters), ]

starters_to_examine %>% 
  mutate(name_short = paste0(substr(`First Name`, 1,1), ". " ,`Last Name`),
         name_team = paste0(`Last Name`, " ", `Team(s)`)) %>% 
  left_join(tibble(clusters, name_short = names(clusters))) %>% 
  select(GP, `SV%`, clusters, name_short, name_team) %>% 
  ggplot(aes(x = GP, y = `SV%`, color = factor(clusters))) +
  geom_point() +
  geom_text(aes(label = name_team, vjust = -0.5, size = 3, alpha = .8)) +
  scale_alpha(guide = FALSE) +
  scale_size(guide = FALSE) +
  ggtitle("Three Clusters of NHL Starting Goalies Regular Season 2017-2018")

# as well as other ways to cluster starters


dend4 <- dends[[4]] %>%  
  set("branches_k_color", k = 4) %>%
  #hang.dendrogram %>%
  plot(main = paste0(linkages_to_example[4], " linkage"))

dend6 <- dends[[6]] %>%  
  set("branches_k_color", k = 4) %>%
  #hang.dendrogram %>%
  plot(main = paste0(linkages_to_example[6], " linkage"))


tanglegram(dends[[4]], dends[[3]], faster = TRUE) %>% 
  plot(main = paste("ward.D2 vs. complete linkage,  entanglement =", round(entanglement(.), 2)))


tanglegram(dends[[4]], dends[[6]], faster = TRUE) %>% 
  plot(main = paste("ward.D2 vs. centroid linkage,  entanglement =", round(entanglement(.), 2)))

# least entanglement with dend 6, centroid linkage



# look at outliers
# distanmce from starting goalie cluster
# and look at it by year
# which player was the biggest outlier for his year?
# which player was the biggest outlier the most times?
# plot animation of centroid drift over time
# can you predict the Vezina?
# at what point int he season can you predict the Vezina?
# How do individual stats track over time, and cluster those TS