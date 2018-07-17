library(ggplot2)
library(ggmcmc)
library(jagsUI)
dir.create("Figures", showWarnings = FALSE)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]

load(file.path(model_data))

mcmc_result<-ggs(samp$samples)

## TRACEPLOTS
beta_traceplot<-ggs_traceplot(mcmc_result, family = "^beta|^r.mean") + theme_bw() 
sigma_traceplot<-ggs_traceplot(mcmc_result, family = "^sigma") + theme_classic() 
lag_traceplot<-ggs_traceplot(mcmc_result, family = "fox.lag|rabbit.lag|food.lag") + theme_bw() 

## R-hat diagnostics
betaRhat<-ggs_Rhat(mcmc_result, family = "^beta|^r.mean") + xlab(expression(paste(hat(R))))+ theme_bw() #BGR diagnostics
sigmaRHat<-ggs_Rhat(mcmc_result, family = "^sigma") + xlab(expression(paste(hat(R))))+ theme_bw() #BGR diagnostics
lagRhat<-ggs_Rhat(mcmc_result, family = "fox.lag|rabbit.lag|food.lag") + xlab(expression(paste(hat(R))))+ theme_bw() #BGR diagnostics

pdf("Figures/Diagnostic_plots.pdf", width=8, height=11, onefile = TRUE)
beta_traceplot
sigma_traceplot
lag_traceplot
betaRhat
sigmaRHat
lagRhat
dev.off()

