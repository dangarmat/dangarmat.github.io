---
layout: post
title: Does less sleep result in more calories eaten?
category: [R, fitbit]
tags: [R, fitbit]
---

![Jun-Dec C v. D](/images/fitbit16.png "Jun-Dec C v. D")

I wanted to know if days I'm running on less sleep, I eat more to make up for it. Fortunately I have FitBit data. Bottom line up front: I found no association between hours of sleep the night before and calories recorded the next day (p = 0.241). In the process found a possible lever I could use.

Fitbit data currently can be [downloaded from one's user account](https://www.fitbit.com/export/user/data). This is limited to daily level data, and downloads of a month at a time. I reccomend the .xls format for easier processing in R.

![fitbit's download site](/images/fitbit01.png "fitbit's download site")

These download as the date of export so I renamed them to each month

![fitbit's downloaded data](/images/fitbit02.png "fitbit's downloaded data")

So here I've got six months of data. Now, my key starting hypothesis is my daily calorie consumption depends on my hours of sleep the night before. In particular, I expect a negative association - the less I slept, the more I ate.

So I'm going to need a handful of packages to efficiently get to this answer and pursue my sub-queries along the way. These packages, to be specific:
```r
require(tidyverse)
require(readxl)
require(lubridate)
require(ggthemes)
require(stringr)
require(purrr)
```

### December Data

Once these suckers are loaded, I can explore December, my most recent month. Note Calories has a comma, so needs to be converted to a number. Similarly, Date needs to be converted to a date.

![Dec C v. D 1](/images/fitbit03.png "Dec C v. D 1")

Wow! I've really gone on a diet in late December! My self-discpline is awesome! 

Oh, wait... I see some zeros. And I know I wasn't fasting all of those days. In fact, I happen to know I just didn't record calories some days and usually those non-record days are above average calorie days, if anything. So I can't just impute with the median or mean - I'd bet 2500 is a fair guess. That might be a charitable gift to myself around Christmas given how many calories I bet I actually consumed... In fact the day below 1000 calories is also probably fair to set at 2500 too. So let's fix those and replot.

![Dec C v. D 2](/images/fitbit04.png "Dec C v. D 2")

A less impressive decrease in calories. Let's take a look at a boxplot.

![Dec C v. D 3](/images/fitbit05.png "Dec C v. D 3")

The median's actually kind of high (gasp!). The range looks beleiveable based on my memory of the month - I mean it's December. Let's check out a histogram

![Dec C v. D 4](/images/fitbit06.png "Dec C v. D 4")
This actually doesn't look too normal.

### Let's pull in all six months now
To reduce keystrokes, can use `map` from `purrr` library to get them all into one data object.

![Jun-Dec C v. D 1](/images/fitbit07.png "Jun-Dec C v. D 1")

How many zeros are there? Seem to be a lot of zeros. 


![Jun-Dec C v. D 2](/images/fitbit08.png "Jun-Dec C v. D 2")

So we have a little problem here. Apparently in August and September I took a break from counting calories. November doesn't look that complete either. I think July, August and December we can do something with, but time series analysis is looking less plausible. I'll take just those three months and impute everything 1200 calories or fewer to 2500.


![Jun-Dec C v. D 3](/images/fitbit09.png "Jun-Dec C v. D 3")

Sigh, less impressive a decrease in calories. Let's see the boxplot to get a sense of distribution.


![Jun-Dec C v. D 4](/images/fitbit10.png "Jun-Dec C v. D 4")

Median's actually kind of high and quite a bit of bunching near 2500, the imputed value on my missing days. Histogram...


![Jun-Dec C v. D](/images/fitbit11.png "Jun-Dec C v. D")

We see a ton at the imputed value. It's really kind of uniform otherwise. Actually let's take a look at all non-zeros


![Jun-Dec C v. D](/images/fitbit12.png "Jun-Dec C v. D")

I guess this is why I've been gaining weight the last six months. This isn't really normal but it actually is close to symmetric. Both the median and mean are close to 2300. 

![Jun-Dec C v. D](/images/fitbit13.png "Jun-Dec C v. D")

In fact it so happens this evening I'm at 2284 right now.


### So what is happening on these days I eat above the median?
Original theory goes sleep is a big factor, that a low sleep day is a high calorie day. Let's see.

![Jun-Dec C v. D](/images/fitbit14.png "Jun-Dec C v. D")


I know there are some zeros for amount of sleep as well. How many? 

![Jun-Dec C v. D](/images/fitbit14.png "Jun-Dec C v. D")

Fifteen days. Honestly some of these days I did not sleep but most of them were days the watch band was broken, as it broke twice. You can tell those by the fact I "didn't sleep" multiple days in a row. Those are, 7/22 - 7/29 and 12/15-12/18.
I think the other days could be ones I was travelling maybe and so slept sitting up and it didn't get them. And 12/30 hasn't happened yet.

This tells me the december data is also circumspect, unfortunately. Let's just join everything and remove every cicumspect day.


![Jun-Dec C v. D](/images/fitbit15.png "Jun-Dec C v. D")

Oh dear, a positive slope. Check out by day of week.


![Jun-Dec C v. D](/images/fitbit15.png "Jun-Dec C v. D")







Code used above:

```r
require(tidyverse)
require(readxl)
require(lubridate)
require(ggthemes)
require(stringr)
require(purrr)


December_foods <- read_excel(
  path = "C:/Users/Dan/Documents/R/FitBit/fitbit_export_201712.xls",
  sheet = "Foods")

# doesn't see Calories as a number
glimpse(December_foods)
# both are characters
December_foods$Date <- ymd(December_foods$Date)
December_foods$`Calories In` <-  
  as.numeric(gsub(",", "", December_foods$`Calories In`))

ggplot(December_foods, aes(x = Date, y = `Calories In`)) +
  geom_point() +
  geom_smooth() +
  theme_fivethirtyeight() +
  labs(title = "Calories vs. Date")


assumed_calories_on_blank_days <- 2500
December_foods$`Calories In`[December_foods$`Calories In` <= 1000] <- 
  assumed_calories_on_blank_days

ggplot(December_foods, aes(x = Date, y = `Calories In`)) +
  geom_point() +
  geom_smooth() +
  theme_fivethirtyeight() +
  labs(title = "Calories vs. Date With Imputed Zeros")


ggplot(December_foods, aes(x = 1, y = `Calories In`)) +
  geom_boxplot() +
  theme_fivethirtyeight() +
  labs(title = "Calories in December With Imputed Zeros") +
  coord_flip()


ggplot(December_foods, aes(x = `Calories In`)) +
  geom_histogram(binwidth = 100) +
  theme_fivethirtyeight() +
  labs(title = "Calories in December With Imputed Zeros")



### Let's pull in all six months now
7:12 %>% as.character() %>% str_pad(2, pad = "0") -> data_months
files_to_load <- paste0("C:/Users/Dan/Documents/R/FitBit/fitbit_export_2017" 
                        , data_months, ".xls")
glimpse(files_to_load)

foods <- map(files_to_load, read_excel, sheet = "Foods")

glimpse(foods)
# we have a list of 6 tables, let's combine them all

foods <- bind_rows(foods)
glimpse(foods)
 
# OK have to process same as before
foods$Date <- ymd(foods$Date)
foods$`Calories In` <-  
  as.numeric(gsub(",", "", foods$`Calories In`))

# how many zero days are there this time?
ggplot(foods, aes(x = Date, y = `Calories In`)) +
  geom_point() +
  geom_smooth() +
  theme_fivethirtyeight() +
  labs(title = "Calories vs. Date")
  
  
foods %>% 
  mutate(data_month = month(Date, label = TRUE)) %>%
  group_by(data_month) %>%
  summarize(zero_days = sum(`Calories In` == 0))



foods %>% 
  mutate(data_month = month(Date, label = TRUE)) %>% 
  filter(data_month %in% c("Jul", "Oct", "Dec")) ->
  foods_full_months

assumed_calories_on_blank_days <- 2500
foods_full_months$`Calories In`[foods_full_months$`Calories In` <= 1000] <- 
  assumed_calories_on_blank_days

# replot
ggplot(foods_full_months, aes(x = Date, y = `Calories In`)) +
  geom_point() +
  geom_smooth() +
  theme_fivethirtyeight() +
  labs(title = "Calories vs. Date With Imputed Zeros")



ggplot(foods_full_months, aes(x = 1, y = `Calories In`)) +
  geom_boxplot() +
  theme_fivethirtyeight() +
  labs(title = "Calories With Imputed Zeros") +
  coord_flip()



ggplot(foods_full_months, aes(x = `Calories In`)) +
  geom_histogram(binwidth = 100) +
  theme_fivethirtyeight() +
  labs(title = "Calories With Imputed Zeros")


foods %>% filter(`Calories In` >= 1200) %>% 
  ggplot(aes(x = `Calories In`)) +
  geom_histogram(binwidth = 100) +
  theme_fivethirtyeight() +
  labs(title = "Calories Logged")


### So what is happening on these days I eat above the median?

sleep <- map(files_to_load, read_excel, sheet = "Sleep")

sleep <- bind_rows(sleep)
glimpse(sleep)

# some processing

sleep %>% mutate(Date = as.Date(ymd_hm(`End Time`)), 
                 Minutes_Asleep = as.numeric(`Minutes Asleep`)) %>%
  group_by(Date) %>%
  summarize(`Hours Sleep` = sum(Minutes_Asleep) / 60 ) %>%
  mutate(Weekday = wday(Date, label = TRUE), 
         Weekday2 = factor(Weekday, ordered = FALSE)) ->
  sleep_processed
  
glimpse(sleep_processed)

anti_join(foods, sleep_processed, by = c("Date", "Date"))



foods %>% full_join(sleep_processed, by = "Date") %>%
  filter(`Calories In` > 1200, `Hours Sleep` > 0) ->
  Calories_vs_Sleep

# drumroll
Calories_vs_Sleep %>% ggplot(aes(x = `Hours Sleep`, 
                                 y = `Calories In`)) +
  geom_point() + 
  geom_smooth(se = FALSE, method = "lm") +
  theme_fivethirtyeight() +
  labs(title = "Calories Vs. Sleep")



Calories_vs_Sleep %>% ggplot(aes(x = `Hours Sleep`, 
                                 y = `Calories In`, 
                                 col = as.factor(Weekday))) +
  geom_point() + 
  geom_smooth(se = FALSE, method = "lm") +
  theme_fivethirtyeight() +
  labs(title = "Calories Vs. Sleep by Day of Week")
```
