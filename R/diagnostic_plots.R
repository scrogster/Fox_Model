library(ggplot2)
library(ggmcmc)

load("model_results.Rdata")

## ----traceplot_beta, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='MCMC traceplots for the regression parameters.', dependson="hier_model"----
ggs_traceplot(mcmc_result, family = "^beta|^r.mean") + theme_classic() #BGR diagnostics
ggsave("Figures/beta_traceplots.pdf")
ggsave("Figures/beta_traceplots.png")

## ----traceplot_sigma, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='MCMC traceplots for the error terms.', dependson="hier_model"----
ggs_traceplot(mcmc_result, family = "^sigma") + theme_classic() #BGR diagnostics
ggsave("Figures/sigma_traceplots.pdf")
ggsave("Figures/sigma_traceplots.png")

## ----gelman_diag_beta, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Scale reduction factors for the regression parameters. Values close to one indicate convergence of the MCMC algorithm', dependson="hier_model", fig.width=6, fig.height=6----
ggs_Rhat(mcmc_result, family = "^beta|^r.mean") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics
ggsave("Figures/beta_gelman_diag.pdf")
ggsave("Figures/beta_gelman_diag.png")


## ----gelman_diag_sigma, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Scale reduction factors for the error terms. Values close to one indicate convergence of the MCMC algorithm', dependson="hier_model", fig.width=6, fig.height=6----
ggs_Rhat(mcmc_result, family = "^sigma") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics
ggsave("Figures/sigma_gelman_diag.pdf")
ggsave("Figures/sigma_gelman_diag.png")
