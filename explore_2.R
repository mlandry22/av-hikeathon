if(dir.exists("/Users/mark/Documents/AV-hikeathon/")) setwd("/Users/mark/Documents/AV-hikeathon/")
if(dir.exists("/home/mark/competitions/av-hikeathon/")) setwd("/home/mark/competitions/av-hikeathon/")
library(data.table)
auc<-function (actual, predicted){
  ## overridden from Metrics package to prevent overflow
  r <- rank(predicted)
  n_pos <- sum(actual == 1)
  n_neg <- length(actual) - n_pos
  denominator<-(n_pos * n_neg)
  numerator<-(sum(r[actual == 1]) - n_pos * (n_pos + 1)/2)
  auc <- numerator/denominator
  auc
}

train<-fread("train.csv")
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

test<-fread("test.csv")
### Build a model that can learn to predict probability of a node-pair in the test set to have a chat relation. 
### The test set contains an id and a pairs of nodes
### for which participants are required to predict is_chat on the test set.

ss_head<-fread("sample_submission_only_headers.csv")

train[,.(.N,mean_chat=mean(is_chat))]


train2<-rbind(train,train[,.(node1_id=node2_id,node2_id=node1_id,is_chat)])

train2[,.(.N,chats=sum(is_chat),rt=mean(is_chat)),node1_id][order(-N)][1:20]
train2[,.(contacts=.N,chats=sum(is_chat),rt=mean(is_chat)),node1_id][
  ,.(.N,mean_rt=mean(rt),mean_chats=mean(chats)),floor(contacts/100)][order(floor)]
dcast(train2[,.(contacts=.N,chats=sum(is_chat),rt=mean(is_chat)),node1_id][
  ,.(.N),.(rt=ceiling(rt*10),contacts=pmin(contacts,11))],rt~contacts)

## order seems to have some importance; Number of single connections is 10x when adding node2_id.
q<-train2[,.(records=.N,chats=sum(is_chat)),.(node1_id,node2_id)][records==2]
## order definitely has importance; 19M connections both ways; 102M only one-way
## keep in mind test set has others

## in connection pairs, if there is 1 chat, most likely there is 2.
## 719k vs 270k
q[node1_id!=node2_id,.N,chats][order(chats)]

q2<-train[node1_id %in% q$node1_id & node2_id %in% q$node1_id]
q2[is_chat==0][1:10]

train[,.(.N,rt=mean(is_chat),chats=sum(is_chat)),node1_id==node2_id]
## some self-chats; but 0.1% versus 3.2%

### general idea
###   prepare features like target encodings of network characteristics
###     is-self
###     opposite is present and is_chat; is present and !is_chat; opposite also in test; opposite absent
###   that should form the base rate; then layer in probabilities based on user features

test[1:2]
test[,.N,node1_id %in% train[,unique(node1_id)]]
test[,.N,node1_id %in% train[,unique(node2_id)]]

testRecip<-merge(test,train[,.(node2_id=node1_id,node1_id=node2_id,is_chat)],c("node1_id","node2_id"))
withinTestRecip<-merge(test,test[,.(node2_id=node1_id,node1_id=node2_id)],c("node1_id","node2_id"))
#testRecip[,mean(is_chat)]

testFeatures<-merge(test,testRecip[,.(id,reciprocal_chat=is_chat)],all.x=TRUE)
testFeatures<-merge(testFeatures,withinTestRecip[,.(id,reciprocal_within_test=1)],all.x=TRUE)
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
View(testFeatures[1:100])
## peculiar random test split, it would seem; 11.7M node1 in train; 20k not in train AS NODE1; 11.7M vs 63k for test.node1 as train.node2
## so can target encode node1, node2, node1/node2, node2 as node2, node1 as node1

user[1:2]


