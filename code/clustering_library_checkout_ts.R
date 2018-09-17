# cluster TS of books

library(tidyverse)
library(ggthemes)
library(lubridate)
library(dtwclust)


### load and explore data ----
# path to the Seattle Public Library unzipped files
file_loc <- "D:\\DataDownloads\\seattle-library-checkout-records\\"

# can try direct read from zip file another time
# this only reads the first one
# myData <- read_csv("D:/DataDownloads/seattle-library-checkout-records.zip")

# this will load all files. It's 91M observations and 4.3GB in memory
# if it's too much, can leave three or more consecutive years for the rest of the query to work
checkouts_files <- 
  file_loc %>% 
  list.files(pattern = "Checkouts_By_Title_Data_Lens_", full.names = TRUE)

checkouts <- tibble()
for(file in checkouts_files){
  checkouts <- 
    file %>%
    read_csv() %>% 
    bind_rows(checkouts)
  print(paste0("completed uploading ", file))
}
glimpse(checkouts)
# 92 million rows and 4.3 GB in memory

# this is actually quite slow itself, not sure it's better than the loop
# save and reload since this takes a while to bring in from CSVs
# saveRDS(checkouts, paste0(file_loc, "checkouts.rds")) # saves as 2GB file
# checkouts <- readRDS(paste0(file_loc, "checkouts.rds"))

# which is the unqiue id?
checkouts %>% 
  summarise(n_distinct(BibNumber), 
            n_distinct(ItemBarcode))
# looks like ItemBarCode is an item, BibNumber is a book. Can have multiple ItemBarCodes per BibNumber

top_books <- 
  checkouts %>% 
  group_by(BibNumber) %>% 
  summarise(NbrItems = n_distinct(ItemBarcode)) %>% 
  arrange(desc(NbrItems))
top_books
# whoa, what is that item 1819741 with 1434?
# whoa, what is that item 3030520 with 928?

inventory <- read_csv(paste0(file_loc, "Library_Collection_Inventory.csv"))
glimpse(inventory)

top_books %>% 
  top_n(n = 1, wt = NbrItems) %>% 
  left_join(inventory, by = c("BibNumber" = "BibNum")) %>% 
  select(BibNumber, NbrItems, Title, PublicationYear, Subjects, ItemLocation, ItemCount)
# have unkowns, item 3 is known, though

top_books %>% 
  top_n(n = 3, wt = NbrItems) %>% 
  inner_join(inventory, by = c("BibNumber" = "BibNum")) %>% 
  select(BibNumber, NbrItems, Title, PublicationYear, Subjects, ItemLocation, ItemCount)

# turns out it's a 3G, 4G, LTE internet connection hotspot you can check out free from the library for 21 days
# https://www.spl.org/using-the-library/reservations-and-requests/reserve-a-computer/computers-and-equipment/spl-hotspot
# ncompass-live-circulating-the-internet-how-to-loan-wifi-hotspots-16-638.jpg
  
top_books %>% 
  ggplot(aes(x = NbrItems)) +
  geom_histogram(binwidth = 5)


# does inventory have any duplicates?
inventory %>% 
  select(BibNum, Title, Author) %>% 
  distinct() %>% 
  group_by(BibNum) %>% 
  count() %>% 
  arrange(desc(n)) 
# some
inventory %>% filter(BibNum == 359785) %>% select(Title, Author)
# different versions of title

inventory_clean <- 
  inventory %>% 
  select(BibNum, Title, Author, Publisher) %>% 
  distinct() %>% 
  mutate(
    Title = case_when(
      is.na(Title) & is.na(Author) & is.na(Publisher) ~ "Unknown",
      is.na(Title) & is.na(Author) ~ paste0("Unknown Published by ", Publisher),
      is.na(Title) ~ paste0("Unknown by ", Author),
      TRUE ~ Title
      ),
    Author = case_when(
      is.na(Title) & is.na(Author) ~ "Unknown",
      is.na(Author) ~ paste0(Title, "by Unknown"),
      TRUE ~ Author
    )
  ) %>% 
  select(BibNum, Title, Author) %>% 
  distinct() %>% 
  group_by(BibNum) %>% 
  top_n(n = 1, wt = Title) %>% 
  top_n(n = 1, wt = Author)

rm(inventory)

top_books %>% 
  ggplot(aes(x = NbrItems)) +
  geom_histogram(binwidth = 5)

rm(top_books)

top_barcodes <- 
  checkouts %>% 
  group_by(ItemBarcode) %>% 
  summarise(NbrBibs = n_distinct(BibNumber)) %>% 
  arrange(desc(NbrBibs))
top_barcodes
# now some item, 0010086290326, has multiple Bibliographies in 2016 alone, what is that item?

top_barcodes %>% 
  top_n(n = 1, wt = NbrBibs) %>% 
  left_join(checkouts, by = "ItemBarcode") 
# they're comething called Fast Add, they don't have a CallNumber even

top_barcodes %>% 
  top_n(n = 1, wt = NbrBibs) %>% 
  left_join(checkouts, by = "ItemBarcode") %>% 
  select(BibNumber) %>% 
  distinct() %>% 
  left_join(inventory_clean, by = c("BibNumber" = "BibNum"))
# these guys are not in the inventory at all. They are maybe temporary Barcodes  

top_barcodes %>% 
  ggplot(aes(x = NbrBibs)) +
  geom_histogram(binwidth = 1)

rm(top_barcodes)

### clean data ----
# we see a lot are not in inventory. For the sake of illustration, let's only keep those that are
end_of_time <- max(checkouts$CheckoutDateTime)
first_days_considered <- 1000

checkouts <- 
  checkouts %>% 
  inner_join((inventory_clean %>% select(BibNum, Title, Author)), by = c("BibNumber" = "BibNum")) %>% 
  select(-ItemType, -Collection) %>% 
  mutate(CheckoutDateTime = mdy_hms(CheckoutDateTime))


# We don't have date accquired - could pull in some kind of publication date maybe
# as a proxy let's just use the first date the book was Checked Out
book_start_dates <-
  checkouts %>% 
  group_by(BibNumber) %>% 
  summarise(bib_nbr_start_date = min(CheckoutDateTime)) %>% 
  mutate(days_old = as.numeric(difftime(end_of_time, bib_nbr_start_date, units = "days")))

qplot(book_start_dates$days_old)
# remove the ones that are too old to be fair comparison

too_old <- max(book_start_dates$days_old) - 31 # add a month for safety
book_start_dates <- 
  book_start_dates %>% 
  # use a filter that with inner join selects books we can compare fairly 
  filter(days_old < too_old, days_old > first_days_considered)


checkouts <- 
  checkouts %>%
  inner_join(book_start_dates %>% select(BibNumber, bib_nbr_start_date)) %>%
  mutate(
    day_for_book = floor(as.numeric(difftime(CheckoutDateTime, bib_nbr_start_date, units = "days"))) + 1
  ) %>%
  select(-bib_nbr_start_date)

#Remove FAST ADDs, and grab top 1000 books with in their first 1000 days
checkouts <- 
  checkouts %>% 
  filter(CallNumber != "FAST ADD") %>% 
  filter(day_for_book <= first_days_considered) %>% 
  group_by(BibNumber) %>% 
  summarise(checkout_count = n(),
            copies = n_distinct(ItemBarcode)
  ) %>% 
  # I need to filter on top checkouts in first 1000 days
  # or pick top 100 for each year
  
  # select top 1000 books in terms of checkouts
  top_n(n = 1000, wt = checkout_count) %>% 
  select(BibNumber) %>% 
  left_join(checkouts, by = "BibNumber") %>% 
  group_by(BibNumber) %>% 
  arrange(CheckoutDateTime) %>% 
  mutate(checkout = 1,
         ending_balance = sum(checkout),
         checkout_balance = cumsum(checkout),
         balance_progress = sapply(checkout_balance / ending_balance, FUN=function(x) min(max(x, 0), 1)),
         checkout_transaction = row_number(),
         total_checkouts = n(),
         checkout_progress = checkout_transaction / total_checkouts
  ) %>% 
  ungroup()


checkouts %>% 
  group_by(ItemBarcode) %>% 
  summarise(NbrBibs = n_distinct(BibNumber)) %>% 
  arrange(desc(NbrBibs)) %>% 
  top_n(n = 1, wt = NbrBibs) %>% 
  left_join(checkouts, by = "ItemBarcode") 
# still some dupes but much fewer

min(checkouts$day_for_book) # hope non-zero, given + 1

checkouts
checkouts %>% 
  arrange(desc(checkout_balance))
# does seem to be working


### take look at cleaned data ----

# distribution of checkouts
# combine and aggregate by book-day and count
checkouts_aggregate <- 
  checkouts %>% 
  group_by(BibNumber, Title, day_for_book) %>% 
  summarize(copies = n()) %>% 
  arrange(desc(copies))
checkouts_aggregate
head(checkouts_aggregate)
# the most checked out books on a given day
# surpsiing only 1 is a book
# also the others aren't on day 1 - wonder if it's after Oscar season or something

# don't need this function anymore but it was so cool for when had too much data, keeping it
sample_n_groups = function(tbl, size, replace = FALSE, weight = NULL) {
  # regroup when done
  grps = tbl %>% groups %>% lapply(as.character) %>% unlist
  # check length of groups non-zero
  keep = tbl %>% summarise() %>% ungroup() %>% sample_n(size, replace, weight)
  # keep only selected groups, regroup because joins change count.
  # regrouping may be unnecessary but joins do something funky to grouping variable
  tbl %>% right_join(keep, by=grps) %>% group_by_(.dots = grps)
}

qplot(checkouts_aggregate$copies) + scale_x_log10(labels = scales::comma_format())
qplot(checkouts_aggregate$copies) 

qplot(checkouts_aggregate$day_for_book) + scale_x_log10(labels = scales::comma_format())
# this is surprising really, just keeps going up for years
qplot(checkouts_aggregate$day_for_book)
# this is with correct linear axis it makes a ton of sense - drop off after initial interest
# but drop off could be due to cutoff of 1000 days
ggplot(checkouts_aggregate, aes( x = day_for_book)) +
  geom_histogram(binwidth = 31) + 
  xlim(0, first_days_considered)

quantile(floor(checkouts_aggregate$day_for_book), probs = c(0.01, 0.025, 0.05, 0.95, 0.975, 0.99), na.rm = TRUE)
# these things seem to take off, then slow down

checkouts_aggregate %>% 
  #sample_n_groups(1000) %>% 
  ungroup() %>% 
  ggplot(aes(day_for_book, copies)) +
  geom_jitter(alpha = 0.01) #+
# scale_y_log10(labels = scales::comma_format()) #+
# scale_x_log10()
# this plot is actually super cool. It shows ineffeciencies in the book ordering process

# dist of last days of checkouts
last_days <- 
  checkouts_aggregate %>%
  group_by(BibNumber) %>%
  summarize(last_day = max(day_for_book)) %>%
  mutate(day2 = last_day > (first_days_considered - 365)) # this checks for books that no one checked out in last year
last_days %>%
  ggplot(aes(last_day)) + 
  stat_ecdf(geom = "step", pad = FALSE) + 
  geom_vline(xintercept=30)
qplot(last_days$last_day) 
last_days %>% 
  filter(!is.na(day2)) %>%
  ggplot(aes(last_day)) + 
  geom_histogram() + 
  facet_wrap(~ day2) 
# clearly don't need to worry about these top 1000 new books going out of style
quantile(round(last_days$last_day), probs = seq(0.05, 0.95, 0.05), na.rm = TRUE)

# half are over in 2384 days? 6.5 years.
# this is because of the right-shadow of the data - it misses what happens to the newest books

# seattle library is pretty full
# what is the value of keeping a book on the shelf one more day?

# distribution of checkout progress
balances <- 
  checkouts %>%
  group_by(BibNumber) %>%
  arrange(CheckoutDateTime) %>%
  mutate(checkout_nbr = row_number())

balances %>%
  group_by(BibNumber) %>%
  summarize(checkout_count = n()) %>%
  select(checkout_count) %>%
  ggplot(aes(x = checkout_count)) + geom_histogram()
  
balances %>%
  group_by(BibNumber) %>%
  summarize(checkout_count = n()) %>%
  select(checkout_count) %>%
  as.vector() %>% 
  summary()
# so minimum is 2514 checkouts in this group, max is 18680
# which is the max?

balances %>%
  group_by(BibNumber) %>%
  summarize(checkout_count = n()) %>%
  filter(checkout_count == max(checkout_count)) %>% 
  left_join(inventory_clean, by = c("BibNumber" = "BibNum"))
# people in Seattle loved taking out Into the wild
# there's probably an advanatge to it coming out earlier in this time period

# not so important in this case
balances %>%
  group_by(BibNumber) %>%
  summarize(checkout_count = n()) %>%
  filter(checkout_count < 1000) %>%
  summarise(`Books with less than 1000 Checkouts` = n())

# one copy but multiple checkouts
balances %>%
  group_by(BibNumber, ItemBarcode) %>%
  summarize(transaction_count = n()) %>%
  group_by(BibNumber) %>%
  summarize(transaction_count = sum(transaction_count), copies = n()) %>%
  filter(copies == 1, transaction_count > 1) %>%
  summarise(`Campaigns with Single Contributor, but Multiple Transactions` = n())

balances %>%
  group_by(BibNumber, ItemBarcode) %>%
  summarize(transaction_count = n()) %>%
  group_by(BibNumber) %>%
  summarize(transaction_count = sum(transaction_count), copies = n()) %>%
  filter(copies > 1) %>%
  summarise(`Campaigns with Multiple copies` = n())

book_start_dates %>% 
  filter(days_old >= first_days_considered) %>% 
  select(BibNumber) %>%
  left_join(balances) %>%
  group_by(BibNumber, ItemBarcode) %>%
  summarize(transaction_count = n()) %>%
  group_by(BibNumber) %>%
  summarize(transaction_count = sum(transaction_count), copies = n()) %>%
  filter(copies > 1) %>%
  summarise(`Campaigns with Multiple copies, age >= 1000 days` = n())

rm(balances)

### produce achetype grouping checkout patterns to surface typical patterns ----
# At 1000 days what is the distribution of transaction and balance progress?

checkouts %>%
  filter(day_for_book <= first_days_considered) %>%
  group_by(BibNumber) %>%
  arrange(checkout_transaction) %>%
  summarise(balance_progress = last(balance_progress), checkout_progress = last(checkout_progress)) %>%
  ggplot(aes(checkout_progress)) + geom_histogram()
# really just a proxy for start date

# after 1000 days, none  are completely done checking out
checkouts %>%
  filter(day_for_book <= first_days_considered) %>%
  group_by(BibNumber) %>%
  arrange(checkout_transaction) %>%
  summarise(balance_progress = last(balance_progress), checkout_progress = last(checkout_progress)) %>%
  filter(checkout_progress == 1) %>%
  nrow()

### time series views ----
checkouts %>%
  #sample_n_groups(1000) %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber)) +
  geom_line(alpha = 0.1)

checkouts %>%
  #sample_n_groups(1000) %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber)) +
  geom_line(alpha = 0.1) + 
  xlim(0, first_days_considered)

# is timing an issue here?
checkouts %>%
  left_join(book_start_dates, by = "BibNumber") %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber, color = days_old)) +
  geom_line(alpha = 0.1) + 
  xlim(0, first_days_considered)
# it's a serious issue, however, it's OK, because this just shows proprotion of total checkouts, but we'll filter
# to total checkouts in first 1000 days anyway

# reprocess key stats to reflect first 1000 days only
checkouts <- 
  checkouts %>% 
  filter(day_for_book <= first_days_considered) %>% 
  group_by(BibNumber) %>% 
  arrange(CheckoutDateTime) %>% 
  mutate(checkout = 1,
         ending_balance = sum(checkout),
         checkout_balance = cumsum(checkout),
         balance_progress = sapply(checkout_balance / ending_balance, FUN=function(x) min(max(x, 0), 1)),
         checkout_transaction = row_number(),
         total_checkouts = n(),
         checkout_progress = checkout_transaction / total_checkouts
  ) %>% 
  ungroup()


checkouts %>%
  left_join(book_start_dates, by = "BibNumber") %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber, color = days_old)) +
  geom_line(alpha = 0.1) 
# it still looks differentiated, is that the effect of changing marketing, or library patron practices?

daily_series <- 
  checkouts %>%
  mutate(day_for_book = floor(day_for_book)) %>%
  #filter(day_for_book <= 30) %>%
  group_by(BibNumber, day_for_book) %>%
  #arrange(id) %>%
  summarise(
    balance = last(checkout_balance),
    balance_progress = last(balance_progress),
    checkout = sum(checkout),
    amount_prop = sapply(checkout / first(ending_balance), FUN=function(x) min(max(x, 0), 1)),
    checkouts = n(),
    #transaction_progress = last(transaction_progress)
    checkout_progress = last(checkout_progress)
  ) %>% 
  filter(day_for_book > 0)
summary(daily_series)


# balance
#library(ggthemes)
daily_series %>%
  ggplot(aes(day_for_book, balance, group = BibNumber)) +
  geom_line(alpha = 0.1) +
  #scale_y_log10(labels = scales::comma_format()) +
  labs(x = "Day for book", y = element_blank(), title = "Checkouts") +
  theme_tufte()

# balance progress
daily_series %>%
  ggplot(aes(day_for_book, balance_progress, group = BibNumber)) +
  geom_line(alpha = 0.1)
# can see the ones that burn out fast and a few that have a slow burn
# idea is don't want to pull one of the latter thinking it's one of the former

# checkout amounts
daily_series %>%
  ggplot(aes(day_for_book, checkout, group = BibNumber)) +
  geom_line(alpha = 0.005) +
  scale_y_log10(labels = scales::comma_format())
# looks like same story as before

# Amount per Ending Balance
daily_series %>%
  ggplot(aes(day_for_book, amount_prop, group = BibNumber)) +
  geom_line(alpha = 0.1)
# don't see a new story, not as much drop off as expected maybe

# Transactions
daily_series %>%
  ggplot(aes(day_for_book, checkouts, group = BibNumber)) +
  geom_line(alpha = 0.1) #+
  #scale_y_log10(labels = scales::comma_format())
# looks like same story as before

# Transactions Progress
daily_series %>%
  ggplot(aes(day_for_book, checkout_progress, group = BibNumber)) +
  geom_line(alpha = 0.1)



### Clustering ----

# To perform clustering we need to reshape our data into a matrix of trajectories with each row representing a campaign and each column representing a day of the campaign.

balance_traj <- 
  daily_series %>% 
  filter(day_for_book %in% 1:first_days_considered) %>%
  select(BibNumber, day_for_book, balance) %>%
  spread(day_for_book, balance) %>%
  mutate(`1` = coalesce(`1`, 0)) %>%
  remove_rownames() %>%
  column_to_rownames("BibNumber") %>%
  apply(1, FUN=zoo::na.locf) %>%
  t()
#save(daily_series, daily_series, balance_traj, file = "balance.RData")

amount_traj <-  
  daily_series %>% 
  filter(day_for_book %in% 1:first_days_considered) %>%
  select(BibNumber, day_for_book, checkouts) %>%
  spread(day_for_book, checkouts, fill = 0) %>%
  remove_rownames() %>%
  column_to_rownames("BibNumber")

# Figure of balance trajectories

balance_traj %>%
  as.data.frame() %>%
  rownames_to_column("BibNumber") %>%
  gather(day_for_book, balance, -BibNumber, convert = TRUE) %>%
  ggplot(aes(day_for_book, balance, group = BibNumber)) +
  geom_line(alpha = 0.1) +
  #scale_x_continuous(breaks = 1:4 * 7) +
  #scale_y_log10(labels = scales::comma_format()) +
  labs(x = "Day of book", y = element_blank(), title = "Checkouts") +
  theme_tufte()
# after 2000 days, most exciting new books are no longer

amount_traj %>%
  as.data.frame() %>%
  rownames_to_column("BibNumber") %>%
  gather(day_for_book, amount, -BibNumber, convert = TRUE) %>%
  ggplot(aes(day_for_book, amount, group = BibNumber)) +
  geom_line(alpha = 0.01) +
  #scale_x_continuous(breaks = 1:4 * 7) +
  #scale_y_log10(labels = scales::comma_format()) +
  labs(x = "Day of book", y = element_blank(), title = "Checkout Daily Amount") +
  theme_tufte()

## DTW

pc_dtw4 <- tsclust(balance_traj, k = 4L,
                   distance = "dtw_basic",
                   trace = TRUE, seed = 1234,
                   norm = "L2", window.size = 2L,
                   args = tsclust_args(cent = list(trace = TRUE)))
pc_dtw9 <- tsclust(balance_traj, k = 9L,
                   distance = "dtw_basic",
                   trace = TRUE, seed = 1234,
                   norm = "L2", window.size = 2L,
                   args = tsclust_args(cent = list(trace = TRUE)))
pc_dtw16 <- tsclust(balance_traj, k = 16L,
                    distance = "dtw_basic",
                    trace = TRUE, seed = 1234,
                    norm = "L2", window.size = 2L,
                    args = tsclust_args(cent = list(trace = TRUE)))

# save(pc_dtw4, pc_dtw9, pc_dtw16, file = "pc_dtw.RData")

plot(pc_dtw4, type = "c")

pc_dtw4@centroids
pc_dtw4@cluster
pc_dtw4@datalist %>% as.data.frame() %>%
  gather(campaign_id, balance)

print_clusters <- function(clustering, trajectories = balance_traj){
  centroids <- clustering@centroids[order(clustering@clusinfo$size, decreasing = TRUE)] %>% 
    as.data.frame(col.names = 1:nrow(clustering@clusinfo)) %>% 
    mutate(day_of_campaign = row_number()) %>%
    gather(cluster, balance, -day_of_campaign) %>% 
    mutate(cluster = parse_number(cluster))
  
  tidy_traj <- 
    trajectories %>% 
    as.data.frame() %>% 
    rownames_to_column("book_id") %>%
    mutate(
      # reorder clusters by size
      cluster = match(clustering@cluster, order(clustering@clusinfo$size, decreasing = TRUE)), 
      book_id = as.numeric(book_id)
    ) %>%
    gather(day_of_campaign, balance, -book_id, -cluster, convert = TRUE) 
  
  outlier_books <- 
    tidy_traj %>%
    filter(day_of_campaign == max(day_of_campaign)) %>% 
    group_by(cluster) %>% 
    filter(balance == max(balance) | balance == min(balance)) %>% 
    ungroup() %>% 
    left_join(inventory_clean, by = c("book_id" = "BibNum")) %>% 
    arrange(cluster, balance) %>% 
    mutate(title_short = ifelse(nchar(Title) > 20, paste0(substr(Title, 1, 18), "..."), Title)) %>% 
    select(book_id, title_short, cluster, balance) 
  
  #tidy_traj <- 
  #  tidy_traj %>% 
   # left_join(outlier_books, by = "book_id")
  
  tidy_traj %>% 
    filter(!is.na(Title)) %>% 
    select(book_id, cluster, Title) %>% 
    distinct() %>% 
    mutate(Title = ifelse(nchar(Title) > 20, paste0(substr(Title, 1, 18), "..."), Title)) %>% 
    glimpse()
  
  cluster_label <- function(cluster) {
      
    smallest_book <- 
      tidy_traj %>% 
      rename(cluster2 = cluster) %>% 
      filter(!is.na(Title)) %>% 
      filter(cluster2 == as.numeric(cluster)) %>% 
      filter(balance == min(balance)) %>% 
      select(Title) %>% 
      top_n(n = 1, wt = row_number()) %>% 
      mutate(Title = ifelse(nchar(Title) > 20, paste0(substr(Title, 1, 18), "..."), Title)) %>% 
      as.vector()
    
    smallest_book <- 
      outlier_books[, `cluster` == as.numeric(cluster)]
    
    largest_book <- 
      tidy_traj %>% 
      rename(cluster2 = cluster) %>% 
      filter(!is.na(Title)) %>% 
      filter(cluster2 == as.numeric(cluster)) %>% 
      filter(balance == max(balance)) %>% 
      select(Title)%>% 
      top_n(n = 1, wt = row_number()) %>% 
      mutate(Title = ifelse(nchar(Title) > 20, paste0(substr(Title, 1, 18), "..."), Title)) %>% 
      as.vector()
      
    paste0(cluster, ': ', 
           clustering@clusinfo[order(clustering@clusinfo$size, decreasing = TRUE), 
                                               1][as.numeric(cluster)], 
           ' books, \n from: ', 
           smallest_book,
           "\n to: ",
           largest_book
    )
  }
  
  tidy_traj %>%
    ggplot(aes(day_of_campaign, balance + 1, group=book_id)) + geom_line(alpha = 0.1) +
    geom_line(aes(day_of_campaign, balance + 1, group = NULL), data = centroids, color = "blue") +
    facet_wrap(~ cluster, labeller = labeller(cluster = cluster_label)) + 
    # I don't much like this log scale useage here
    #scale_y_log10(labels = scales::comma_format()) +
    theme_tufte() + 
    labs(x = "Day for Book", y = element_blank(), title = "Checkouts")
}

print_clusters(pc_dtw4)
print_clusters(pc_dtw9)
print_clusters(pc_dtw16)


pc_dtw4@centroids[order(pc_dtw4@clusinfo$size, decreasing = TRUE)] %>% 
  as.data.frame(col.names = 1:4) %>% 
  mutate(day_of_campaign = row_number()) %>%
  gather(cluster, balance, -day_of_campaign) %>% 
  mutate(cluster = parse_number(cluster))

## Shape-based Distance
# k-Shape

pc_sbd4 <- tsclust(balance_traj, type = "p", k = 4L, seed = 1234,
                   distance = "sbd")
pc_sbd9 <- tsclust(balance_traj, type = "p", k = 9L, seed = 1234,
                   distance = "sbd")
pc_sbd16 <- tsclust(balance_traj, type = "p", k = 16L, seed = 1234,
                    distance = "sbd")
#save(pc_sbd4, pc_sbd9, pc_sbd16, file = "pc_sbd.RData")
pc_sbd4

plot(pc_sbd4, type="sc")


print_clusters(pc_sbd4)
print_clusters(pc_sbd9)
print_clusters(pc_sbd16)
