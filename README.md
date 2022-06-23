# Mistake Pitches

Files for a project trying to define and evaluate so-called "mistake pitches" in the 2021 MLB Season. This repo currently contains the mistakes.R file which contains all code for various models and plots, as well as comments about the modeling process. There is also an .Rmd file which contains much of the same code, used to generate the pdf which contains the writeup and final plots. All data used is from [Baseball Savant](http://baseballsavant.com/) and was originally scraped using the [baseballr](https://billpetti.github.io/baseballr/) package.

## Problem Statement
My goal with this project is to explore the concept of the "mistake pitch." A couple of the questions I look to answer are:
- How do you define a mistake pitch?
- What makes a pitch a mistake?
- What pitchers are the most/least mistake prone?

## Data Collection
For this project, I scraped Statcast data from Baseball Savant using the baseballr package. This data was initially scraped into R, and then written to a local MySQL database. This database contains data for every pitch since the 2008 season, though for this project I only used pitches from the 2021 season. I then queried only the necessary data from MySQL back into R for modeling and analysis.

## Data Modeling
I used two models in this project, one to predict whether a pitch would be ["barreled"](https://www.mlb.com/glossary/statcast/barrel) and one to predict whether a pitch would be swung at or called a strike. These models were both gradient boosted tree models.

## Results
#### How do you define a mistake pitch?
This is more of a philosphical question than a modeling question. I specifically define a mistake pitch that is likely to get barreled, by the Statcast definition.

#### What makes a pitch a mistake?
As expected, location is the most important feature of the barrel model.

![barrel_features](https://user-images.githubusercontent.com/64282166/175399477-7e6e8ec0-8f46-46f6-9edd-dda1f1234a43.png)

#### What pitchers are the most/least mistake prone?
To look at which pitchers/pitches were the most or least mistake prone, I used the results from both the barrels model and the "chances" model. This enabled me to look at the pitches that were able to avoid barrels while still generating strikes (chances). Here is an example results table, more can be found in the full writeup.

![barrel_prone_p](https://user-images.githubusercontent.com/64282166/175402747-d683f36f-cf47-4767-8d82-ef4dd07fe12d.png)

