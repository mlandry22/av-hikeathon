if(dir.exists("/Users/mark/Documents/AV-hikeathon/")) setwd("/Users/mark/Documents/AV-hikeathon/")
if(dir.exists("/home/mark/competitions/av-hikeathon/")) setwd("/home/mark/competitions/av-hikeathon/")
library(data.table)

s1<-fread("submissions/woduhotu_preds_a8e6436c-v4.csv")
s2<-fread("submissions/dosovona_preds_6a37fc07-v4b.csv")
s3<-fread("tofucige_preds_eb7b9386-4c.csv")
s4<-fread("kevepuve_preds_27b6df0b-4d.csv")

submission<-fread("submissions/sub_2019-04-05_15_34.csv")
submission[,is_chat:=s1$target.1*0.25 + s2$target.1*0.25 + s3$target.1*0.25 + s4$target.1*0.25]

fName<-paste0("blend_",substr(gsub(" ","_",gsub(":","_",as.character(Sys.time()))),1,16),".csv")
fwrite(submission,fName)
system(paste0("pigz --fast --zip ",fName))
