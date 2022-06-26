# library
library(tidyverse)

# Reference: https://www.r-graph-gallery.com/circular-barplot.html
# by Yan Holtz

# Create dataset
nameLakes <- c("Tr\u00E9s Marias", "Sobradinho", "Itaparica", "Or\u00F3s", "Castanh\u00E3o",
  "Armando Ribeiro Gon\u00E7alves", "Coremas", "Lake St. Clair", "Lake Erie")
data <- data.frame(
  individual=rep(nameLakes, 3),
  group=c( rep('Streamflow', 9), rep('Water elevation', 9), rep('Evaporation', 9)) ,
  value=sample( seq(0,1,0.01), 27, replace=T)
)

# Set a number of 'empty bar' to add at the end of each group
empty_bar <- 2
to_add <- data.frame( matrix(NA, empty_bar*nlevels(data$group), ncol(data)) )
colnames(to_add) <- colnames(data)
to_add$group <- rep(levels(data$group), each=empty_bar)
data <- rbind(data, to_add)
data <- data %>% arrange(group)
data$id <- seq(1, nrow(data))

# Get the name and the y position of each label
label_data <- data
number_of_bar <- nrow(label_data)
angle <- 90 - 360 * (label_data$id-0.5) /number_of_bar     # I substract 0.5 because the letter must have the angle of the center of the bars. Not extreme right(1) or extreme left (0)
label_data$hjust <- ifelse( angle < -90, 1, 0)
label_data$angle <- ifelse(angle < -90, angle+180, angle)

# prepare a data frame for base lines
base_data <- data %>% 
  group_by(group) %>% 
  summarize(start=min(id), end=max(id) - empty_bar) %>% 
  rowwise() %>% 
  mutate(title=mean(c(start, end)))

# Make the plot
p <- ggplot(data, aes(x=as.factor(id), y=value, fill=group)) +       # Note that id is a factor. If x is numeric, there is some space between the first bar
  
  geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0) +
  
  # Add a val=100/75/50/25 lines. I do it at the beginning to make sur barplots are OVER it.
  geom_segment(x = 0.25, y = 1, xend = 32.5, yend = 1, colour = "grey90", size=0.3) +
  geom_segment(x = 0.25, y = 0.8, xend = 32.25, yend = 0.8, colour = "grey90", size=0.3) +
  geom_segment(x = 0.25, y = 0.6, xend = 32, yend = 0.6, colour = "grey90", size=0.3) +
  geom_segment(x = 0.25, y = 0.4, xend = 32, yend = 0.4, colour = "grey90", size=0.3) +
  geom_segment(x = 0.25, y = 0.2, xend = 31.75, yend = 0.2, colour = "grey90", size=0.3) +
  
  # Add text showing the value of each 100/75/50/25 lines
  annotate("text", x = rep(max(data$id),5), y = c(0.2, 0.4, 0.6, 0.8, 1), label = c("0.2", "0.4", "0.6", "0.8", "1") , color="grey", size=4 , angle=0, fontface="bold", hjust=1) +
  
  geom_bar(aes(x=as.factor(id), y=value, fill=group), stat="identity", alpha=0.8) +
  ylim(-0.75,1.2) +
  theme_minimal() +
  theme(
    legend.position = "none",
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(-1,4), "cm") 
  ) +
  coord_polar() + 
  geom_text(data=label_data, aes(x=id, y=value+0.1, label=individual, hjust=hjust), color="black", fontface="bold",alpha=0.6, size=3.5, angle= label_data$angle, inherit.aes = FALSE ) +
  
  # Add base line information
  geom_segment(data=base_data, aes(x = start, y = -0.05, xend = end, yend = -0.05), colour = "black", alpha=0.8, size=0.6 , inherit.aes = FALSE )  +
  geom_text(data=base_data, aes(x = title, y = -0.18, label=group), vjust=c(2,0,2.5), hjust=c(0.5,0.5,0.5), colour = "black", alpha=0.8, size=4, fontface="bold", angle= c(310,10,70), inherit.aes = FALSE)

p
