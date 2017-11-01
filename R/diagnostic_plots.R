library(ggplot2)
library(ggmcmc)
library(jagsUI)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]

load(file.path(model_data))

mcmc_result<-ggs(samp$samples)

## ----traceplot_beta----
ggs_traceplot(mcmc_result, family = "^beta|^r.mean") + theme_classic() #BGR diagnostics
ggsave("Figures/beta_traceplots.pdf", height=10, width=7)
ggsave("Figures/beta_traceplots.png", height=10, width=7)

## ----traceplot_sigma----
ggs_traceplot(mcmc_result, family = "^sigma") + theme_classic() #BGR diagnostics
ggsave("Figures/sigma_traceplots.pdf", height=10, width=7)
ggsave("Figures/sigma_traceplots.png", height=10, width=7)

## ----traceplot_lags----
ggs_traceplot(mcmc_result, family = "fox.lag|rabbit.lag|food.lag") + theme_classic() #BGR diagnostics
ggsave("Figures/lag_traceplots.pdf", height=10, width=7)
ggsave("Figures/lag_traceplots.png", height=10, width=7)


## ----gelman_diag_beta----
ggs_Rhat(mcmc_result, family = "^beta|^r.mean") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics
ggsave("Figures/beta_gelman_diag.pdf")
ggsave("Figures/beta_gelman_diag.png")


## ----gelman_diag_sigma----
ggs_Rhat(mcmc_result, family = "^sigma") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics
ggsave("Figures/sigma_gelman_diag.pdf")
ggsave("Figures/sigma_gelman_diag.png")

## ----gelman_diag_lags----
ggs_Rhat(mcmc_result, family = "fox.lag|rabbit.lag|food.lag") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics
ggsave("Figures/lag_gelman.pdf", height=10, width=7)
ggsave("Figures/lag_gelman.png", height=10, width=7)

