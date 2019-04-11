## set locations; set up to work on my laptop or workstation without changing anything
if(dir.exists("/Users/mark/Documents/AV-hikeathon/")) setwd("/Users/mark/Documents/AV-hikeathon/")
if(dir.exists("/home/mark/competitions/av-hikeathon/")) setwd("/home/mark/competitions/av-hikeathon/")
library(data.table)

full_train<-fread("train.csv")
full_train[,id:=.I]
### Where node1_id and node2_id are anonymised identifiers for users who are in each other’s phone address book. 
### is_chat signifies their chat relationship. 
### is_chat is 1, if the first user sends a chat message with the second user, and 0 otherwise.

user<-fread("user_features.csv")
### This file contains some anonymised features for all nodes/users. 
### Here node_id (corresponding to node1_id and node2_id in train/test files) 
###   represents the user for whom we have features from f1 to f13
### Mostly these features convey information around how active the users are in the 
###   app for the given time period - different slices of user engagement metrics. 
### f13 is a categorical feature, 
### f1-f12 are ordinal features each representing no. of days a user did some specific 
###   activity on the app in the last 31 days.

full_test<-fread("test.csv")
### Build a model that can learn to predict probability of a node-pair in the test set to have a chat relation. 
### The test set contains an id and a pairs of nodes
### for which participants are required to predict is_chat on the test set.

ss_head<-fread("sample_submission_only_headers.csv")

### general idea
###   prepare features like target encodings of network characteristics
###     is-self
###     opposite is present and is_chat; is present and !is_chat; opposite also in test; opposite absent
###   that should form the base rate; then layer in probabilities based on user features

## use these variables to rotate data sets
## the final model created a training set with cvMode<-TRUE & MOD_SPLIT values of 0 and 1; then cvMode FALSE for test set
cvMode<-TRUE
MOD_SPLIT<-1
if(cvMode==TRUE){
  ## train and test here are for feature creation, so it's really out-of-sample; 
  ## the test set will be the only one used for modeling (and itself split into train/val/test for Driverless AI)
  train<-full_train[id%%8!=MOD_SPLIT] ## just using arbitrary but repeatable way of splitting train/test, not fileId as a feature
  test<-full_train[id%%8==MOD_SPLIT]
  setnames(test,"is_chat","target")
} else {
  train<-copy(full_train)
  test<-copy(full_test)
  test[,target:=NA]
}

trainRecip<-merge(train,train[,.(node2_id=node1_id,node1_id=node2_id,recip_chat=is_chat)],c("node1_id","node2_id"))
trainWhenRecip1<-trainRecip[recip_chat==1,.(recip1_contacts=.N,chats_when_recip1=sum(is_chat),chatRt_when_recip1=mean(is_chat)),node1_id]
trainWhenRecip0<-trainRecip[recip_chat==0,.(recip0_contacts=.N,chats_when_recip0=sum(is_chat),chatRt_when_recip0=mean(is_chat)),node1_id]
testRecip<-merge(test,train[,.(node2_id=node1_id,node1_id=node2_id,is_chat)],c("node1_id","node2_id"))
withinTestRecip<-merge(test,test[,.(node2_id=node1_id,node1_id=node2_id)],c("node1_id","node2_id"))
#testRecip[,mean(is_chat)]

testFeatures<-merge(test,testRecip[,.(id,reciprocal_chat=is_chat)],"id",all.x=TRUE)
testFeatures<-merge(testFeatures,withinTestRecip[,.(id,reciprocal_within_test=1)],"id",all.x=TRUE)
testFeatures[,.N,.(reciprocal_chat,reciprocal_within_test)]
testFeatures<-merge(testFeatures,train[,.(node1_contactsAsNode1=.N,node1_chatsAsNode1=sum(is_chat)
                                          ,node1_ChatRtAsNode1=round(mean(is_chat),4)),node1_id]
                    ,"node1_id",all.x=TRUE)
testFeatures<-merge(testFeatures,train[,.(node2_contactsAsNode2=.N,node2_chatsAsNode2=sum(is_chat)
                                          ,node2_ChatRtAsNode2=round(mean(is_chat),4)),node2_id]
                    ,"node2_id",all.x=TRUE)
testFeatures<-merge(testFeatures,train[,.(node1_contactsAsNode2=.N,node1_chatsAsNode2=sum(is_chat)
                                          ,node1_ChatRtAsNode2=round(mean(is_chat),4)),.(node1_id=node2_id)]
                    ,"node1_id",all.x=TRUE)
testFeatures<-merge(testFeatures,train[,.(node2_contactsAsNode1=.N,node2_chatsAsNode1=sum(is_chat)
                                          ,node2_ChatRtAsNode1=round(mean(is_chat),4)),.(node2_id=node1_id)]
                    ,"node2_id",all.x=TRUE)
## these features were not used by the model; they were added iteratively and did not improve the model meaningfully,
##  so these features were left out
testFeatures<-merge(testFeatures,trainWhenRecip1,by="node1_id",all.x=TRUE)
testFeatures<-merge(testFeatures,trainWhenRecip0,by="node1_id",all.x=TRUE)
testFeatures[reciprocal_chat==0 | is.na(reciprocal_chat),chatRt_when_recip1:=NA]
testFeatures[reciprocal_chat==1 | is.na(reciprocal_chat),chatRt_when_recip0:=NA]
#View(testFeatures[1:100])

testFeatures<-merge(testFeatures,user,by.x="node1_id",by.y="node_id",all.x=TRUE)
setnames(testFeatures,paste0("f",1:13),paste0("n1_f",1:13))
testFeatures<-merge(testFeatures,user,by.x="node2_id",by.y="node_id",all.x=TRUE)
setnames(testFeatures,paste0("f",1:13),paste0("n2_f",1:13))
testFeatures[,`:=`(
    sameNode=as.numeric(node1_id==node2_id) ## occurs fairly frequently and most of them are is_chat==0.
    ,ml_sub_f9=n1_f9-n2_f9
    ,ml_sub_f11=n1_f11-n2_f11
    ,ml_sub_f13=n1_f13-n2_f13
    #,ml_third_n1=n1_f3+n1_f6+n1_f9+n1_f12
    #,ml_third_n2=n2_f3+n2_f6+n2_f9+n2_f12
    #,ml_third_n1n2=n1_f3+n1_f6+n1_f9+n1_f12+n2_f3+n2_f6+n2_f9+n2_f12
    #,n1_n2_chat_rt=node1_ChatRtAsNode1*node2_ChatRtAsNode2
    #,n2_n1_chat_rt=node1_ChatRtAsNode2*node2_ChatRtAsNode1
)]  

testFeatures[,`:=`(recip1_contacts=NULL,chats_when_recip1=NULL,recip0_contacts=NULL,chats_when_recip0=NULL)]

#connection_set<-train[node2_id %in% c(testFeatures[,unique(node2_id)],testFeatures[,unique(node1_id)])]
#for(n1 in connection_set[,unique(node1_id)]){
#  n1_set<-connection_set[node1_id==n1]
#  for(n2 in n1_set[,unique(node2_id)])
#}

#testFeatures[,.(.N,mean(target)),.(x=n1_f3+n1_f6+n1_f9+n1_f12+n2_f3+n2_f6+n2_f9+n2_f12)][order(-x)]
#testFeatures[,.(.N,mean(target)),.(x=n1_f2+n1_f5+n1_f8+n1_f11+n2_f2+n2_f5+n2_f8+n2_f11)][order(-x)]
#testFeatures[,.(.N,mean(target)),.(x=n1_f3+n1_f6+n1_f9+n1_f12+n2_f3+n2_f6+n2_f9+n2_f12)][order(-x)]

if(cvMode==TRUE){
  fwrite(testFeatures[1000001:7000000],"hike_dai_train5b.csv")
  fwrite(testFeatures[7000001:8000000],"hike_dai_valid5b.csv")
  fwrite(testFeatures[8000001:nrow(testFeatures)],"hike_dai_test5b.csv")
} else {
  fwrite(testFeatures,"hike_final_test.csv")
}

create_submission<-FALSE
if(create_submission==TRUE){
  ## used blend of four predictions, some not submitted independently, only used in the blend
  dai<-fread("woduhotu_preds_a8e6436c-v4.csv")
  submission<-testFeatures[,.(id,is_chat=0)]
  submission[,is_chat:=dai[,target.1]]

  fName<-paste0("sub_",substr(gsub(" ","_",gsub(":","_",as.character(Sys.time()))),1,16),".csv")
  fwrite(submission,fName)
  system(paste0("pigz --fast --zip ",fName))
}
