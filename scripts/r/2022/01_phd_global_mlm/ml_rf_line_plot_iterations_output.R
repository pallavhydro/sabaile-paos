
### OUTPUT VISUALIZATION: RANDOM FOREST
###
### Author:     Pallav Kumar Shrestha
### Date:       27.07.2022
### Licence:    CC BY 4.0






# READ data
# ---------------------------------------------

path_d = "~/work/projects/09_phd/03_sim/02_randomforest/exp/3195/predictor_set_1_1000iterations/"

data_yrs_t  = read.table(paste(path_d, file = "yrs_t_mat_2d.txt", sep = "/"), sep = ",", header = T)
data_yrs_iv = read.table(paste(path_d, file = "yrs_iv_mat_2d.txt", sep = "/"), sep = ",", header = T)
data_raw    = read.table(paste(path_d, file = "iteration_output.txt", sep = "/"))
data_pro    = data_raw[c(2, 5, 6)]
colnames(data_pro) = c("iteration", "kge_t", "kge_v")           



# OPTIMAL
# ---------------------------------------------
# iteration
opti_iter = which.max(data_pro$kge_v)
# validation
opti_kge_v = max(data_pro$kge_v)
# training (coresponding to opti from validation)
opti_kge_t = data_pro$kge_t[which.max(data_pro$kge_v)]

data_pro$kge_v_opt = data_pro$kge_v
data_pro$kge_v_opt[data_pro$kge_v != max(data_pro$kge_v)] = NA
data_pro$kge_t_opt = NA
data_pro$kge_t_opt[which.max(data_pro$kge_v)] = data_pro$kge_t[which.max(data_pro$kge_v)]




# PLOT Performance across ITERATIONS (NOTE: need to add this to the end of main ml_rf iterative script, so that the latter makes plots as soon as iteration is complete)
# -------------------------------------

# TRUE to enable things to be drawn outside the plot region
par(xpd=FALSE) 

# plot
plot(data_pro$kge_t, ylim = c(0, 1), xlab = "Iterations of random ordering of years", 
     ylab = "KGE", col = "blue", tcl = 0.5)
title("RANDOM FOREST: Rappbode dam outflow\n", adj = 0, cex.main = 1.2)
title("\n\nPerformance of training and validation", adj = 0, cex.main = 1)
points(data_pro$kge_v, col = "red")
points(data_pro$kge_t_opt, col = "black", lwd = 4, bg = "blue", type = "p", pch = 21, cex = 2)
points(data_pro$kge_v_opt, col = "black", lwd = 4, bg = "red", type = "p", pch = 21, cex = 2)
abline(a = 0.84, b = 0, lwd = 3, lty = 2, col = "black") # chronology maintained training performance
abline(a = 0, b = 0, lwd = 3, lty = 1, col = "black") # chronology maintained validation performance

# add legend
legend("topright", inset = c(0, 0), 
       legend = c("training (random)", "validation (random)", "training (chronology)", "validation (chronology)"), 
       pch = c(21, 21, NA, NA), lty = c(NA, NA, 2, 1), lwd = c(NA, NA, 3, 3),  col = c("blue", "red", "black", "black"),
       ncol = 2)



# RF Best iteration
# --------------------------------------------------------

yrs_t = as.numeric(data_yrs_t[opti_iter,])
yrs_v = as.numeric(data_yrs_iv[opti_iter,])





