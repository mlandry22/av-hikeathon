# av-hikeathon
Analytics Vidhya Hikeathon

### Preface & Plan for Contents
(iterating quickly on April 10th to ensure compliance)

Throughout the day will add:
* basic setup
* pre-processing where the features are created using most of the data to get averages and counts, and a separate holdout set for the modeling set; this is already available in `explore_2.R`
* high level description and observations

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
