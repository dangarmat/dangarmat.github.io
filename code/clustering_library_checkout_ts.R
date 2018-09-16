# cluster TS of books

library(tidyverse)
library(lubridate)
library(ggthemes)
library(dtwclust)


### load and explore data ----
file_loc <- "D:\\DataDownloads\\seattle-library-checkout-records\\"

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
  select(Title, PublicationYear, Subjects, ItemLocation, ItemCount)



top_books %>% 
  top_n(n = 1, wt = NbrItems) %>% 
  inner_join(inventory, by = c("BibNumber" = "BibNum")) %>% 
  select(Title, PublicationYear, Subjects, ItemLocation, ItemCount)

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
# tons
inventory %>% filter(BibNum == 359785) %>% select(Title, Author)

inventory_clean <- 
  inventory %>% 
  select(BibNum, Title, Author) %>% 
  distinct() %>% 
  group_by(BibNum) %>% 
  top_n(n = 1, wt = Title) %>% 
  top_n(n = 1, wt = Author)

rm(inventory)

# can see a lot are not in inventory. For the sake of illustration, let's only keep those that are
checkouts <- 
  checkouts %>% 
  inner_join((inventory_clean %>% select(BibNum, Title, Author)), by = c("BibNumber" = "BibNum"))

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
  ggplot(aes(x = NbrBibs)) +
  geom_histogram(binwidth = 1)

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

rm(top_barcodes)

### clean data ----
#Remove FAST ADDs, and books with less than 1 copy
checkouts <- 
  checkouts %>% 
  filter(CallNumber != "FAST ADD") %>% 
  group_by(BibNumber) %>% 
  summarise(checkout_count = n(),
            copies = n_distinct(ItemBarcode)
  ) %>% 
  # select top 7000 books in terms of number of copies ever checked out
  # later will reduce to 1000 again
  top_n(n = 7000, wt = copies) %>% 
  select(BibNumber) %>% 
  left_join(checkouts, by = "BibNumber") %>% 
  mutate(CheckoutDateTime = mdy_hms(CheckoutDateTime))
end_of_time <- max(checkouts$CheckoutDateTime)

checkouts %>% 
  group_by(ItemBarcode) %>% 
  summarise(NbrBibs = n_distinct(BibNumber)) %>% 
  arrange(desc(NbrBibs)) %>% 
  top_n(n = 1, wt = NbrBibs) %>% 
  left_join(checkouts, by = "ItemBarcode") 
# still some dupes but much fewer

# We don't have date accquired - could pull in some kind of pulication date maybe
# as a proxy let's just use the first date the book was Checked Out
book_start_dates <-
  checkouts %>% 
  group_by(BibNumber) %>% 
  summarise(bib_nbr_start_date = min(CheckoutDateTime)) %>% 
  mutate(days_old = as.numeric(difftime(end_of_time, bib_nbr_start_date, units = "days")))

checkouts <- 
  checkouts %>%
  inner_join(book_start_dates %>% select(BibNumber, bib_nbr_start_date)) %>%
  mutate(
    day_for_book = floor(as.numeric(difftime(CheckoutDateTime, bib_nbr_start_date, units = "days"))) + 1
  ) %>%
  select(-bib_nbr_start_date)

oldest_book <- max(book_start_dates$days_old)
min(checkouts_aggregate$day_for_book) # hope non-zero


checkouts <- 
  book_start_dates %>% 
  # remove new books and old books so have fair middle group to compare
  filter(days_old >= 1000,
         days_old <= oldest_book - 100) %>% 
  select(BibNumber) %>% 
  left_join(checkouts, by = "BibNumber") %>% 
  # take it down to top 2000
  group_by(BibNumber) %>% 
  summarise(copies = n_distinct(ItemBarcode)
  ) %>% 
  # final reduce to 1000 books
  top_n(n = 1000, wt = copies) %>% 
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
  )

checkouts
checkouts %>% 
  arrange(desc(checkout_balance))
# does seem to be working


### take look at cleaned data ----

# distribution of checkouts
# combine and aggregate by book-day and count
checkouts_aggregate <- 
  checkouts %>% 
  group_by(BibNumber, day_for_book) %>% 
  summarize(copies = n()) %>% 
  arrange(desc(copies))
checkouts_aggregate

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

checkouts_aggregate %>% 
  #sample_n_groups(1000) %>% 
  ungroup() %>% 
  ggplot(aes(day_for_book, copies)) +
  geom_jitter(alpha = 0.1) +
  scale_y_log10(labels = scales::comma_format()) #+
  #scale_x_log10()
# this plot is actually super cool. It shows ineffeciencies in the book ordering process

qplot(checkouts_aggregate$copies) + scale_x_log10(labels = scales::comma_format())

qplot(checkouts_aggregate$day_for_book) + scale_x_log10(labels = scales::comma_format())
# this is surprising really, just keeps going up for years
qplot(checkouts_aggregate$day_for_book)
# this is with correct linear axis it makes a ton of sense - drop off after initial interest

quantile(floor(checkouts_aggregate$day_for_book), probs = c(0.01, 0.025, 0.05, 0.95, 0.975, 0.99), na.rm = TRUE)
# these things seem to take off


# dist of last days of checkouts
last_days <- 
  checkouts_aggregate %>%
  group_by(BibNumber) %>%
  summarize(last_day = max(day_for_book)) %>%
  mutate(day2 = last_day > 1) # this removes cases where books were checked out on the first day only
last_days %>%
  ggplot(aes(last_day)) + 
  stat_ecdf(geom = "step", pad = FALSE) + 
  geom_vline(xintercept=30)
qplot(last_days$last_day) + 
  scale_x_log10()
last_days %>% 
  filter(!is.na(day2)) %>%
  ggplot(aes(last_day)) + 
  geom_histogram() + 
  facet_wrap(~ day2) + 
  scale_x_log10(labels = scales::comma_format())
# clearly don't need to worry about day one only checkouts here, different mechanism
quantile(round(last_days$last_day), probs = seq(0.05, 0.95, 0.05), na.rm = TRUE)

# half are over in 2384 days? 6.5 years.
# out of 365, clearly a different pattern

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
  qplot() + scale_x_log10(labels = scales::comma_format())

# not so important in this case, as already filtered out
balances %>%
  group_by(BibNumber) %>%
  summarize(checkout_count = n()) %>%
  filter(checkout_count == 1) %>%
  summarise(`Books with only One Checkout` = n())

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
  filter(days_old >= 1000) %>% 
  select(BibNumber) %>%
  left_join(balances) %>%
  group_by(BibNumber, ItemBarcode) %>%
  summarize(transaction_count = n()) %>%
  group_by(BibNumber) %>%
  summarize(transaction_count = sum(transaction_count), copies = n()) %>%
  filter(copies > 1) %>%
  summarise(`Campaigns with Multiple copies, age >= 1000 days` = n())


### produce achetype grouping checkout patterns to surface typical patterns ----
# At 30 days what is the distribution of transaction and balance progress?

checkouts %>%
  filter(day_for_book <= 1000) %>%
  group_by(BibNumber) %>%
  arrange(checkout_transaction) %>%
  summarise(balance_progress = last(balance_progress), checkout_progress = last(checkout_progress)) %>%
  ggplot(aes(checkout_progress)) + geom_histogram()

# after 1000 days, a handful are completely done checking out
checkouts %>%
  filter(day_for_book <= 1000) %>%
  group_by(BibNumber) %>%
  arrange(checkout_transaction) %>%
  summarise(balance_progress = last(balance_progress), checkout_progress = last(checkout_progress)) %>%
  filter(checkout_progress == 1) %>%
  nrow()

### time series views ----
checkouts %>%
  #sample_n_groups(1000) %>% 
  ungroup() %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber)) +
  geom_line(alpha = 0.1)

checkouts %>%
  #sample_n_groups(1000) %>% 
  ungroup() %>% 
  ggplot(aes(day_for_book, balance_progress, group = BibNumber)) +
  geom_line(alpha = 0.1) + 
  xlim(0, 365)

daily_series <- 
  checkouts %>%
  mutate(day_for_book = floor(day_for_book) + 1) %>%
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
  scale_y_log10(labels = scales::comma_format()) +
  labs(x = "Day for book", y = element_blank(), title = "Checkouts (log-scale)") +
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
# don't see a story

# Transactions
daily_series %>%
  ggplot(aes(day_for_book, checkouts, group = BibNumber)) +
  geom_line(alpha = 0.1) +
  scale_y_log10(labels = scales::comma_format())
# looks like same story as before

# Transactions Progress
daily_series %>%
  ggplot(aes(day_for_book, checkout_progress, group = BibNumber)) +
  geom_line(alpha = 0.1)



### Clustering ----

# To perform clustering we need to reshape our data into a matrix of trajectories with each row representing a campaign and each column representing a day of the campaign.

balance_traj <- 
  daily_series %>% 
  filter(day_for_book %in% 1:1000) %>%
  select(BibNumber, day_for_book, balance) %>%
  spread(day_for_book, balance) %>%
  mutate(`1` = coalesce(`1`, 0)) %>%
  remove_rownames() %>%
  column_to_rownames("BibNumber") %>%
  apply(1, FUN=zoo::na.locf) %>%
  t()
save(daily_series, daily_series, balance_traj, file = "balance.RData")

amount_traj <-  
  daily_series %>% 
  filter(day_for_book %in% 1:1000) %>%
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
  scale_y_log10(labels = scales::comma_format()) +
  labs(x = "Day of book", y = element_blank(), title = "Checkouts (log-scale)") +
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
  labs(x = "Day of book", y = element_blank(), title = "Checkout Daily Amount (log-scale)") +
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

save(pc_dtw4, pc_dtw9, pc_dtw16, file = "pc_dtw.RData")

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
    left_join(inventory_clean, by = c("book_id" = "BibNum")) %>% 
    arrange(balance) %>% 
    select(book_id, Title, Author) 
  
  tidy_traj <- 
    tidy_traj %>% 
    left_join(outlier_books, by = "book_id")
  
  cluster_label <- function(cluster) {
    paste0(cluster, '\n', clustering@clusinfo[order(clustering@clusinfo$size, decreasing = TRUE), 
                                              1][as.numeric(cluster)], 
           ' books from: ', 
           (tidy_traj %>% filter(`cluster` == cluster, balance == max(balance)) %>% select(Title)),
           " to: ",
           (tidy_traj %>% filter(`cluster` == cluster, balance == min(balance)) %>% select(Title))
    )
  }
  
  tidy_traj %>%
    ggplot(aes(day_of_campaign, balance + 1, group=book_id)) + geom_line(alpha = 0.1) +
    geom_line(aes(day_of_campaign, balance + 1, group = NULL), data = centroids, color = "blue") +
    facet_wrap(~ cluster, labeller = labeller(cluster = cluster_label)) + 
    # I don't much like this log scale useage here
    #scale_y_log10(labels = scales::comma_format()) +
    #theme_tufte() + 
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
save(pc_sbd4, pc_sbd9, pc_sbd16, file = "pc_sbd.RData")
pc_sbd4

plot(pc_sbd4, type="sc")


print_clusters(pc_sbd4)
print_clusters(pc_sbd9)
print_clusters(pc_sbd16)
