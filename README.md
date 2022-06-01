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
