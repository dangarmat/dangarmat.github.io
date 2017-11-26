---
layout: post
title: Hello World! Here's a Normal Distribution!
category: R
tags: R
---

This is a first post to see if this works. This simulated Normal(0,1) different times and shows how smaller samples can vary quite a bit more from the true distribution than large samples. This shows where I'd like to go with this too - adding a function that can call this. It's not a fascinating picture, although there is a deep mystery in there, or several. Can we know the truth? Isn't everything we know based on a sample? Is everything we beleive subject to future information?

```r
require(tidyverse)
require(tidyr)

random_simulations_1 <- tibble(rnorm(100000)) %>%
  gather %>% rename(distribution = key, observed = value)

random_simulations_2 <- tibble(rnorm(1000)) %>%
  gather %>% rename(distribution = key, observed = value) %>% bind_rows(random_simulations_1)

random_simulations <- tibble(rnorm(10)#, rnorm(100)  
                             #runif(100)#,  
                             #rhyper(100, 100, 50, 10), 
                             #rbinom(100, 10, .5)
                             ) %>%
  gather %>% rename(distribution = key, observed = value) %>% bind_rows(random_simulations_2)

# note we've repeated three times, time for a function
# also note there are other distributions to try this on
# and really, it may ne nice to simulate a few pulls of the same size

ggplot(random_simulations, aes(observed, fill = as.factor(distribution))) +
  geom_density(alpha = 0.2) + labs(title = "Simulate N(0,1)")

```
