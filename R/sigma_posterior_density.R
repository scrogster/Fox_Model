require(ggplot2)
require(ggmcmc)
require(dplyr)
library(grid)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[2])

out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

sigma_result<-data.frame(samp$sims.list$sigma) %>%
	rename('sigma[1]'=X1, 'sigma[2]'=X2, 'sigma[3]'=X3, 'sigma[4]'=X4) %>%
	gather()	%>%
	rename(Parameter=key)

#code to put proper math notation in facet labels of plot
pname<-as_labeller(c(
	'sigma[1]'="sigma[process]^fox",
	'sigma[2]'="sigma[process]^rabbit",
	'sigma[3]'="sigma[transect]^fox",
	'sigma[4]'="sigma[transect]^rabbit")
	, label_parsed
)

ggplot(sigma_result, aes(x=value, group=Parameter))+
	geom_density(fill="grey", alpha=0.3)+
	facet_wrap(~Parameter,  labeller=pname)+
	xlab("")+
	ylab("")+
	xlim(0, NA)+
	theme_bw()+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.1, vjust=-0.1),
		 panel.border = element_rect(colour = "black"))

ggsave(out_pdf)
ggsave(out_png)