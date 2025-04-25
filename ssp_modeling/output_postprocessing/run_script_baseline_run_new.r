rm(list=ls())

library(data.table)
#regions 

#Set root directory
#root<- "C:/Users/fuent/OneDrive - Instituto Tecnologico y de Estudios Superiores de Monterrey/SISEPUEDE/Uganda/"
#root<- "/Users/fabianfuentes/Library/CloudStorage/OneDrive-InstitutoTecnologicoydeEstudiosSuperioresdeMonterrey/SISEPUEDE/Uganda/"
#setwd(root)
#load emissions targets 
te_all<-read.csv("scr/BaU/emission_targets_uganda_non_energy.csv")
target_country <- "UGA"
te_all<-te_all[,c("Subsector","Gas","Vars","Edgar_Class",target_country)]
te_all[,"tvalue"] <- te_all[,target_country]
te_all[,target_country] <- NULL
target_vars <- unlist(strsplit(te_all$Vars,":"))

#ouputfile
output.folder <- "data/ssp_run/2025_04_24/"
output.file<-"sisepuede_results_sisepuede_run.csv"

data_all<-read.csv(paste0(output.folder,output.file))
rall <- unique(data_all$region)

#set params of rescaling function
dir.output <- output.folder
initial_conditions_id <- "_0"
time_period_ref <- 7

dim(data_all)
data_all <- subset(data_all,time_period>=time_period_ref)
dim(data_all)

#revise which sector-gas ids are zero at baseline 
te_all$simulation <- 0
for (i in 1:nrow(te_all))
 {
   # i<- 12
    vars <- unlist(strsplit(te_all$Vars[i],":"))
    if (length(vars)>1) {
    te_all$simulation[i] <- as.numeric(rowSums(data_all[data_all$primary_id==gsub("_","",initial_conditions_id) &  data_all$time_period==time_period_ref,vars]))
    } else {
     te_all$simulation[i] <- as.numeric(data_all[data_all$primary_id==gsub("_","",initial_conditions_id) &  data_all$time_period==time_period_ref,vars])   
    }
  }
te_all$simulation <- ifelse(te_all$simulation==0 & te_all$tvalue>0,0,1)
correct<- aggregate(list(factor_correction=te_all$simulation),list(Edgar_Class=te_all$Edgar_Class),mean)
te_all <- merge(te_all,correct,by="Edgar_Class")
te_all$tvalue <- te_all$tvalue/te_all$factor_correction
te_all$simulation<-NULL 
te_all$factor_correction<-NULL
te_all$Edgar_Class<-NULL

#now run

source(paste0("scr/BaU/","rescale_function_baseline_mapping_timeref.r"))
z<-1
rescale(z,rall,data_all,te_all,initial_conditions_id,dir.output,time_period_ref)    

