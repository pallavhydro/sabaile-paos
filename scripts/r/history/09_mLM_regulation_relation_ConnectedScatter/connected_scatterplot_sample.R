# Libraries
library(ggplot2)
library(dplyr)
library(babynames)
library(ggrepel)
library(tidyr)
library(hrbrthemes)

# data
data <- babynames %>% 
  filter(name %in% c("Ashley", "Amanda")) %>%
  filter(sex=="F") %>%
  filter(year>1970) %>%
  select(year, name, n) %>%
  spread(key = name, value=n, -1)

# Select a few date to label the chart
tmp_date <- data %>% sample_frac(0.3)

# plot 
data %>% 
  ggplot(aes(x=Amanda, y=Ashley, label=year)) +
  geom_point(color="#69b3a2") +
  geom_text_repel(data=tmp_date) +
  geom_segment(color="#69b3a2", 
               aes(
                 xend=c(tail(Amanda, n=-1), NA), 
                 yend=c(tail(Ashley, n=-1), NA)
               ),
               arrow=arrow(length=unit(0.3,"cm"))
  ) +
  theme_ipsum()