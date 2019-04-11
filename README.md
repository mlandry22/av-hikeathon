# av-hikeathon
Analytics Vidhya ML Hikeathon competition  
Contest Page: https://datahack.analyticsvidhya.com/contest/hikeathon  
Team: Vopani & Mark  
Score: 0.9324549106 (5th)  

### Technical Specifications ###
* Physical
  * Dell Precision T7810
  * dual Xeon e5-2630 v3 (32 cores)
  * 128 GB memory
  * Titan X Pascal {for Driverless AI, not feature creation}
* Software
  * Ubuntu 16.04 LTS
  * R version 3.5.1
  * data.table 1.11.8
  * Driverless AI version 1.5.3

### Modeling Flow: Holdout Sets ###
Due to the impressive luxury of data, our team never created a machine learning model on the entire data. Initial models were run on 2 million rows and later 4 million and 6 million. But diminishing returns were certainly showing as those sizes were increased.
But the entire data set was used for the overall modeling process, we just locked in a full modeling architecture and rather than use K-fold cross-validation to create K sets, we used only two and iterated only one portion.

The ratio of train records to test records was about 1/8th. So to set up the modeling flow, 1/8th of the data was used as the out-of-fold sample. This leaves about 8 million records.
That out-of-fold sample is used to apply features from the other 7/8th and ensure prevention of leakage in the simplest way.
The out-of-fold sample is further subdivided for the modeling where: 
* 6 million were used for training the model
* 1 million for validation, which in Driverless AI affects how the features are chosen and the model architecture tuning
* 1 million for a separate test set, not used for feature or hyperparameter tuning so a better representation of new data

Again, this could have been iterated 8 times to produce 8 different out-of-fold modeling sets, and we used only two. Also the subdivision of the out-of-fold sample could be iterated (and was early on, when using 2M/2M/1M for train/valid/test). But in the final models, only one subdivision was taken.

In the code you can see the row IDs are used. In no way does this use rowId or the order of the file as a modeling feature; it is merely a simpler way to ensure consistency and reproducibility. 

### Features ###

[modeling_day1.R](https://github.com/mlandry22/av-hikeathon/blob/488015be3d6efab47081fc45e20b875e60434ca2/modeling_day1.R#L38) creates extracts that were loaded into Driverless AI for modeling.
The code to create these feature extracts was able to be run top to bottom in a matter of minutes on the workstation shown above, taking advantage of data.table's ability to read and write in parallel and perform fast in-memory computations and merges.

All of the top five listed advantages of data.table from the package's [wiki](https://github.com/Rdatatable/data.table/wiki) are utilized in this code:
* fast and friendly delimited file reader: ... is now parallelized on CRAN May 2018 and presented earlier [here](https://github.com/Rdatatable/data.table/wiki/talks/BARUG_201704_ParallelFread.pdf).
* fast and parallelized file writer: ?fwrite announced [here](http://blog.h2o.ai/2016/04/fast-csv-writing-for-r/) and on CRAN in Nov 2016.
* parallelized row subsets - See this [benchmark for timings](https://github.com/Rdatatable/data.table/issues/1660#issuecomment-212142342)
* fast aggregation of large data; e.g. 100GB in RAM (see [benchmarks](https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping) on up to two billion rows)
* fast add/update/delete columns by reference by group using no copies at all

The user data columns were merged to both nodes (lines 81-84)
A few interactions were created from these: the subtraction of node2's value from node1's value for features 9, 11, and 13. These were chosen from feature importance of the base features. All subtractions were later tried, but did not provide sufficient improvement to retain. Feature13 is a categorical coded as numeric, so the subtraction does not necessarily make sense, though it will show the model where feature13 was the same without having to hope the decision trees would always utilize that interaction. Later a full interaction was used, to no avail; and a pre-computed mean(target) was used, also without significant improvement.

Counts and averages were computed about each of the four scenarios of the two nodes in the test record. The number of contacts, number of chats, and average chat rate were computed for each of (a) node1 when in node1; (b) node1 when in node2; (c) node2 when in node2; (d) node2 when in node1. This can be thought of as a directional graph, particularly with respect to chats.

The most powerful feature in the data set was whether or not a node2 had sent node1 a chat. So a quick join on reversed roles was done to provide the target, which therefore indicated a 1 (chat), 0 (in contacts, but no chat), and NA (not in contacts). These occur in lines 51 and 54. Features digging even deeper into the _reciprocal_ behavior were created and experimented with, but did not show significant improvement.

Because it does occur that users include themselves in their own contacts, and occasionally but rarely chat with themself (different devices, perhaps?), a feature to indicate that node1 was the same as node2 was created.

The actual values of `node1_id` and `node2_id` were not provided to the model. These nodes are merely represented by their respective features in this feature creation step--the merge with user data and the counts and averages and the flag of whether the two nodes were the same.

Early modeling showed that AUC was about 0.897 on internal validation when the users features were not included at all, only the various contact/chat calculations per node & role, and reciprocal behavior feature were included.
Internal validation (which was consistent, but a little lower than the leaderboard figures) is shown for the final feature sets in the next section.

### Driverless AI Models ###

The following screenshot shows the results of four different Driverless AI experiments.
The results of these were blended evenly, in [simple_blend.R](https://github.com/mlandry22/av-hikeathon/blob/master/simple_blend.R) to produce the final submission.

![image](https://user-images.githubusercontent.com/2976822/55935672-cdd84d80-5bf9-11e9-9217-fa8b340d3b63.png)

model | parameters | data set
--- | --- | ---
kevepuve | 6/2/1 | train4 
tofucige | 6/2/1 | train4b
dosovona | 5/2/1 | train4 
woduhotu | 5/2/1 | train4b

Where train4 uses `MOD_SPLIT<-0` in [modeling_day1.R line 38](https://github.com/mlandry22/av-hikeathon/blob/488015be3d6efab47081fc45e20b875e60434ca2/modeling_day1.R#L38) and train4b uses `MOD_SPLIT<-1`. The data sets are identical otherwise.

And the accuracy settings of 5 and 6 are the only difference in the pairs of models, with the impact being that all 6 million rows were used for the 6/2/1 models and about 80% or so used for the 5/2/1, and also the ensembling step is more advanced.

Further details of each model:
Experiment kevepuve
![image](https://user-images.githubusercontent.com/2976822/55935615-a08b9f80-5bf9-11e9-9d5d-1c2891b18893.png)

Experiment tofucige
![image](https://user-images.githubusercontent.com/2976822/55935570-894cb200-5bf9-11e9-9243-bc7310448c6a.png)

Experiment dosovona
![image](https://user-images.githubusercontent.com/2976822/55935519-6de1a700-5bf9-11e9-8668-d7f55d79d65f.png)

Experiment woduhotu
![image](https://user-images.githubusercontent.com/2976822/55935460-4d195180-5bf9-11e9-9a71-e75cbbcd7699.png)

Cheers!
Will be updating quickly

~Mark
