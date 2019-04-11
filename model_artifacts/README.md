This directory is used to provide three sets of zip files for each of the four models used, using the Driverless AI interface.

### mojo-[experiment].zip ###
The files needed to score new data in a fast production setting. These are about 5MB each, compared to the python scoring pipelines which are about 250MB.
Produced using the button `DOWNLOAD MOJO SCORING PIPELINE` (after building, which took only a few seconds for each model)

### h2oai_experiments_summary_[experiment].zip ###
A collection of text and json files showing the original features provided, full variable importance of the final model including generated/calculated features (features.tab.txt), settings (preview.txt), model progression/leaderboard (tuning_leaderboard.txt), and results (summary.txt)

### h2oai_experiments_logs_[experiment].zip ###
Detailed log files of each experiment showing the transformations and models attempted in the training pipeline, spanning feature engineering, model tuning, and ensembling.

