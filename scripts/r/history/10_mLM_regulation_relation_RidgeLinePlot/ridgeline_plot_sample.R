# library
library(ggridges)
library(ggplot2)
library(viridis)
library(hrbrthemes)


# Plot sample from R-graph-gallery.com
ggplot(lincoln_weather, aes(x = `Mean Temperature [F]`, y = `Month`, fill = ..x..)) +
  geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
  scale_fill_viridis(option = "D") +
  labs(title = 'Temperatures in Lincoln NE in 2016') +
  theme_ipsum() +
  theme(
    legend.position="none",
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8)
  )

# Plot
month <- month.name[as.numeric(format(index(data_mon[,1]),"%m"))]
month <- factor(month, levels = month.name)
ggplot(data_mon, aes(x = `data_tavg_ups_mon`, 
                     y = month, 
                     # y = as.factor(month.name[as.numeric(format(index(data_mon[,1]),"%m"))]), 
                     fill = ..x..)) +
  geom_density_ridges_gradient(scale = 3, rel_min_height = 0.01) +
  scale_fill_viridis(option = "B") +
  labs(title = 'Temperatures in Tres Marias') +
  theme_ipsum() +
  theme(
    legend.position="none",
    panel.spacing = unit(0.1, "lines"),
    strip.text.x = element_text(size = 8)
  )
