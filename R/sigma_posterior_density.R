require(ggplot2)
require(ggmcmc)
require(dplyr)
library(grid)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[2])
out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

beta_result<-ggs(samp, family="^sigma")

#code to put proper math notation in facet labels of plot
pname<-as_labeller(c(
	'sigma[1]'="sigma[process]^fox",
	'sigma[2]'="sigma[process]^rabbit",
	'sigma[3]'="sigma[transect]^fox",
	'sigma[4]'="sigma[transect]^rabbit")
	, label_parsed
)

ggplot(beta_result, aes(x=value, group=Parameter))+
	geom_density(fill="green", alpha=0.3)+
	facet_wrap(~Parameter,  labeller=pname)+
	xlab("")+
	ylab("")+
	theme_classic()+
	theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

ggsave(out_pdf)
ggsave(out_png)