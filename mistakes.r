# Try to define what is a mistake pitch.

# Here are some factors to consider:
# - location is obviously the big one, for each pitch type.
# - also pitch "quality" should be considered, compared to the movement/velocity of that pitcher's pitch

# How  to go about this?

# Lets look at all pitches from the 2021 season.
# 
# 1. How will we evaluate mistake pitches?
#   - I am going to look at the likelihood that that pitch would go for a particularly high run value. 
#     I think this is better than just looking at a predicted run value for that pitch. Obviously 3-0 fastballs
#     that miss by a foot are bad, but it doesn't really fit my definition of a "mistake"
# 

  # - The second decision I need to make is if I am comparing pitchers to themselves or to the league. That is,
  # Jacob deGrom compared to the league is probably throwing 0 mistake pitches. But surely he has some pitches
  # that have a high probability of being crushed relative to himself.

# .0674

source(file = "config.R")
library(tidyverse)
library(baseballr)
library(RMySQL)
library(xgboost)
library(Ckmeans.1d.dp)
library(MLmetrics)
library(mltools)
library(data.table)
library(SHAPforxgboost)

con <- dbConnect(MySQL(), dbname = dbname, 
                 user = user, 
                 password = password, 
                 host = host)


query <- "SELECT * FROM statcast_full WHERE game_year = 2021"

sc <- dbGetQuery(con, query)

dbDisconnect(con)

sc <- sc %>%
  select(-row_names, -spin_dir:-break_length_deprecated, -game_type, -hit_location, -game_year, -on_3b:-on_1b,
         -hc_x:-sv_id, -pitcher_1:-fielder_9)

# instead of creating an expected run value model and then setting some xrv threshold for "crushed", I'm
# just gonna use barrels as a proxy

# So we'll just predict the probability of a barrel for each pitch (expected barrels) and then look to see who
# leads the league.

# I will also look at "barrel chances." This will be a better denominator than pitches for calculating an
# xBarrel rate (xbarrels/"chance" instead of xbarrels/pitch)


##### DATA PRE-PROCESSING ######################################################

# these are the "chances" (swings + called strikes)
# I want to train a model to predict the probability that a pitch will be swung at or
#   called a strike
chances <- c("called_strike", "foul", "foul_tip", "hit_into_play", 
             "swinging_strike", "swinging_strike_blocked")

# this step filters out all the bunt attempts that I can discern
# Since players who are bunting aren't attempting to barrel the ball, I throw these pitches out.
sc <- sc %>%
  filter(!(type == "X" & grepl(" bunt", des))) %>%
  filter(!(grepl("bunt", description))) %>%
  filter(!is.na(plate_x) | !is.na(release_speed) | !is.na(release_pos_z)) %>%
  mutate(chance = ifelse(description %in% chances, 1, 0))

# this step takes features that measure in the x direction (horizontal movement/location)
# and flips their sign (i.e. negative values become positive.)
# This is done to make lefties pitches look like righties pitches to help the model train
# more accurately.
data <- sc %>%
  mutate(plate_x = ifelse(p_throws == "L", -1*plate_x, plate_x),
         pfx_x = ifelse(p_throws == "L", -1*pfx_x, pfx_x),
         release_pos_x = ifelse(p_throws == "L", -1*release_pos_x, release_pos_x)) %>%
  mutate_at(c("release_speed", "plate_x", "plate_z", "pfx_x", "pfx_z", "release_pos_x", "release_pos_z"),
            ~(scale(.) %>% as.vector))

# making some features
data <- data %>%
  mutate(barrel = ifelse(is.na(barrel), 0, barrel),
         same_hand = ifelse(p_throws == stand, 1, 0),
         stand = ifelse(stand == "R", 1, 0),
         balls = ifelse(balls == 4, 3, balls),
         count = factor(str_c(as.character(balls), as.character(strikes), sep = "-")),
         chance = ifelse(description %in% chances, 1, 0)
         )

# one hot encoding categorical features that I want to include in the model
data <- one_hot(as.data.table(data), cols = "count")


# Now that all of our data preprocessing is done, I have to split the train and test set.

##### MODEL BUILDING ###########################################################




train_size <- floor(0.75 * nrow(data))
set.seed(123)
train_ind <- sample(seq_len(nrow(data)), size = train_size)

train <- data[train_ind, ]
valid <- data[-train_ind, ]

# What we want to do is train two models:
#   - A model that predicts the probability of a pitch being barrelled.
#   - A model that predicts the probablitiy of a pitch being swung at or called for a strike.


# XGBOOST
# barrel model

xgb_data <- train %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z, 
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`, 
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

barrel_label <- train$barrel

barrel_cv <- xgb.cv(data = as.matrix(xgb_data), label = barrel_label, nrounds = 50, nthread = 2, nfold = 5,
                    metrics = "logloss", max_depth = 3, eta = 1, objective = "binary:logistic")

eval_log <- as.data.frame(barrel_cv$evaluation_log)
nrounds_barrel <- which.min(eval_log$test_logloss_mean)

barrel_mod <- xgboost(data = as.matrix(xgb_data), label = barrel_label, max.depth = 3, 
                      eta = 1, nthread = 2, nrounds = nrounds_barrel, objective = "binary:logistic")


# shap_values <- shap.values(xgb_model = barrel_mod, X_train = as.matrix(xgb_data))
# shap_values$mean_shap_score
# 
# shap_scores <- shap_values$shap_score
# 
# # shap.prep() returns the long-format SHAP data from either model or
# shap_scores_long <- shap.prep(xgb_model = barrel_mod, X_train = as.matrix(xgb_data))
# # is the same as: using given shap_contrib
# shap_scores_long <- shap.prep(shap_contrib = shap_scores, X_train = as.matrix(xgb_data))
# 
# shap.plot.summary(shap_scores_long)


xgb_valid <- valid %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`, 
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

# make preds on validation set
barrel_preds <- predict(barrel_mod, as.matrix(xgb_valid))

barrel_loss <- LogLoss(barrel_preds, valid$barrel)

data <- data %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`, 
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

full_barrel_preds <- predict(barrel_mod, as.matrix(data))

sc$xBarrel <- full_barrel_preds


# Chance Model

chance_label <- train$chance

chance_cv <- xgb.cv(data = as.matrix(xgb_data), label = chance_label, nrounds = 175, nthread = 2, nfold = 5,
                    metrics = "logloss", max_depth = 3, eta = 1, objective = "binary:logistic")

# getting the proper number of model iterations to prevent under/overfitting
eval_log <- as.data.frame(chance_cv$evaluation_log)
nrounds_chance <- which.min(eval_log$test_logloss_mean)
#nrounds_chance <- 136

# train models
chance_mod <- xgboost(data = as.matrix(xgb_data), label = chance_label, max.depth = 3,
                      eta = 1, nthread = 2, nrounds = nrounds_chance, objective = "binary:logistic")


chance_preds <- predict(chance_mod, as.matrix(xgb_valid))

chance_loss <- LogLoss(chance_preds, valid$chance)


# Feature Importance

# Compute feature importance matrix
barrel_importance <- xgb.importance(colnames(xgb_data), model = barrel_mod)
chance_importance <- xgb.importance(colnames(xgb_data), model = chance_mod)

# Nice graph
xgb.ggplot.importance(barrel_importance[1:10,]) +
  theme_bw() +
  theme(
    legend.position = "none"
  ) +
  labs(
    title = "Feature Importance for XGBoost Model Predicting Barrels"
  )

xgb.plot.importance(chance_importance[1:10,])

full_chance_preds <- predict(chance_mod, as.matrix(data))

sc$xChance <- full_chance_preds

mistake_thresh <- 0.15



##### PLOTS ####################################################################

sc %>%
  filter(xBarrel > mistake_thresh) %>%
  ggplot(aes(plate_x, plate_z)) +
  geom_point(size = 4, alpha = 0.5, aes(color = stand)) +
  geom_segment(x = -5/6, y = 3.67, xend = -5/6 , yend = 1.52) + # draw strikezone
  geom_segment(x = 5/6, y = 3.67, xend = 5/6 , yend = 1.52) +
  geom_segment(x = -5/6, y = 3.67, xend = 5/6 , yend = 3.67) +
  geom_segment(x = -5/6, y = 1.52, xend = 5/6 , yend = 1.52) +
  coord_fixed() +
  theme_bw() +
  xlim(-1,1) +
  ylim(1.5,3.75)

sc %>%
  filter(barrel == 1) %>%
  ggplot(aes(plate_x, plate_z)) +
  geom_point(size = 4, alpha = 0.5, aes(color = stand)) +
  geom_segment(x = -5/6, y = 3.67, xend = -5/6 , yend = 1.52) + # draw strikezone
  geom_segment(x = 5/6, y = 3.67, xend = 5/6 , yend = 1.52) +
  geom_segment(x = -5/6, y = 3.67, xend = 5/6 , yend = 3.67) +
  geom_segment(x = -5/6, y = 1.52, xend = 5/6 , yend = 1.52) +
  coord_fixed() +
  theme_bw() +
  xlim(-1,1) +
  ylim(1.5,3.75)

playername_lookup(608337)

chadwick_player_lu_table <- chadwick_player_lu_table %>%
  select(name_first, name_last, key_mlbam)

####

sc <- sc %>%
  mutate(mistake = ifelse(xBarrel >= mistake_thresh, 1, 0))

p_barrels <- sc %>%
  group_by(pitcher) %>%
  summarize(pitches = n(),
            mistakes = sum(mistake),
            chances = sum(chance),
            barrels = sum(barrel, na.rm = TRUE),
            xbarrels = sum(xBarrel),
            xchances = sum(xChance),
            barrel_rate = barrels/pitches,
            xbarrel_rate = xbarrels / pitches,
            xbpc = xbarrels/xchances) %>%
  left_join(chadwick_player_lu_table, by = c("pitcher" = "key_mlbam"))

p_barrels %>%
  filter(pitches > 750) %>%
  arrange((xbpc))

b_barrels <- sc %>%
  group_by(batter) %>%
  summarize(pitches_seen = n(),
            barrels = sum(barrel, na.rm = TRUE),
            xbarrels_pitch = sum(xBarrel),
            barrel_rate = barrels/pitches_seen,
            xbarrel_rate = xbarrels_pitch / pitches_seen) %>%
  left_join(chadwick_player_lu_table, by = c("batter" = "key_mlbam"))

b_barrels %>%
  arrange((barrels - xbarrels_pitch)) 

b_barrels %>%
  ggplot(aes(pitches_seen, xbarrels_pitch)) +
  geom_point()




p_barrels %>%
  summarize(total_barrels = sum(barrels, na.rm = TRUE),
            total_xbarrels = sum(xbarrels))  

# I really should be looking at barrel rate as it relates to swing rate.
# Really my definition of a mistake pitch is a pitch that gets swung at a lot and also gets barreled a lot.

# right now I'm rewarding pitches that are never swung at the same as a really good pitch.
# my goal is to characterize what matters when it comes to a mistake pitch.

# Right now, when I look at the feature importance graph, I think it is overrating pitch location because
# pitch locations that never get swings are being weighted the same as pitches that get lots of swings but
# few barrels.

mistakes <- sc %>%
  filter(mistake == 1)

mistakes %>% 
  arrange((plate_x))

# xbarrels heatmap
sc %>%
  filter(abs(plate_x) < 5) %>%
  filter(pitch_type %in% c("FF", "CH", "CU", "FC", "KC", "SI", "SL", "FS")) %>%
  ggplot(aes(plate_x, plate_z, z = xBarrel)) + 
  geom_tile(binwidth = .25, stat = "summary_2d", fun = mean, 
              na.rm = TRUE) +
  theme_bw() +
  coord_fixed() +
  labs(
    x = "Horizontal Pitch Location",
    y = "Vertical Pitch Location",
    title = "Barrel Probability by Pitch Location",
    fill = "Barrel Probability"
  )

# barrels heatmap
sc %>%
  filter(abs(plate_x) < 5) %>%
  filter(pitch_type %in% c("FF", "CH", "CU", "FC", "KC", "SI", "SL", "FS")) %>%
  ggplot(aes(plate_x, plate_z, z = barrel)) + 
  geom_tile(binwidth = .25, stat = "summary_2d", fun = mean, 
            na.rm = TRUE) +
  theme_bw() +
  coord_fixed() +
  labs(
    x = "Horizontal Pitch Location",
    y = "Vertical Pitch Location",
    title = "Barrel Rate (per pitch) by Pitch Location",
    fill = "Barrels/Pitch"
  )



# What percentage of bip are barrels?
# If I wanted to change my target from barrels to "barrels adjusted for batter," I would want to take the
# top X % of each batter's batted balls, where X is the percentage of total balls in play that are barrels 

sc %>%
  filter(type == "X") %>%
  summarize(prop = sum(barrel, na.rm = TRUE)/n())
# About 7.5 % of all batted balls are barrels

# Let's do some binning and look at results that way.

sc %>%
  group_by(zone) %>%
  summarize(barrel_rate = mean(barrel, na.rm = TRUE)) %>%
  arrange(desc(barrel_rate))

sc %>%
  group_by(pitch_type) %>%
  summarize(barrel_rate = mean(barrel, na.rm = TRUE),
            n = n())

colSums(is.na(sc))


# Let's write a for loop that goes through each pitch and splits the data into 4 or 5 partitions
# by some feature like x_mov or velocity then we can summarize these partitions by barrel rate or xbarrels etc.


sl <- sc %>%
  filter(p_throws == "R") %>%
  filter(pitch_type == "SL")


slr <- quantile(sl$pfx_x, probs = seq(0, 1, 0.25))

sl <- sl %>%
  mutate(movz_bin = case_when(
    pfx_x > slr[4] ~ 4,
    pfx_x > slr[3] ~ 3,
    pfx_x > slr[2] ~ 2,
    TRUE ~ 1
  ))

sl %>%
  group_by(movz_bin) %>%
  summarize(barrel_rate = mean(barrel, na.rm = TRUE))
