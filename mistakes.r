# Try to define what is a mistake pitch.

# Here are some factors to consider:
# - location is obviously the big one, for each pitch type.
# - also pitch "quality" should be considered, compared to the movement/velocity of that pitcher's pitch

# How  to go about this?

# Lets look at all pitches from the 2021 season.
# 
#  How will we evaluate mistake pitches?
#   - I am going to look at the likelihood that that pitch would go for a particularly high run value. 
#     I think this is better than just looking at a predicted run value for that pitch. Obviously 3-0 fastballs
#     that miss by a foot are bad, but it doesn't really fit my definition of a "mistake"
# 

# Libraries
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

options(scipen = 999999)

# Connect to local MySQL database to retrieve Statcast data
con <- dbConnect(MySQL(), dbname = dbname, 
                 user = user, 
                 password = password, 
                 host = host)

# Looking only at 2021 season
query <- "SELECT * FROM statcast_full WHERE game_year = 2021"
sc <- dbGetQuery(con, query)
dbDisconnect(con)

# Remove columns I know I won't use
sc <- sc %>%
  select(-row_names, -spin_dir:-break_length_deprecated, -game_type, -hit_location, -game_year, -on_3b:-on_1b,
         -hc_x:-sv_id, -pitcher_1:-fielder_9)

##### DATA PRE-PROCESSING ######################################################

# these are what I call "chances" (swings + called strikes)
# I want to train a model to predict the probability that a pitch will be swung at or called for a strike
# to be used in conjunction with my model for predicting barrels
chances <- c("called_strike", "foul", "foul_tip", "hit_into_play", 
             "swinging_strike", "swinging_strike_blocked")

# this step filters out all the bunt attempts that I can discern
# Since players who are bunting aren't attempting to barrel the ball, I throw these pitches out.
# I also filter out the few observations that don't have location, pitch velo or release position data.
sc <- sc %>%
  filter(!(type == "X" & grepl(" bunt", des))) %>%
  filter(!(grepl("bunt", description))) %>%
  filter(!is.na(plate_x) | !is.na(release_speed) | !is.na(release_pos_z)) %>%
  mutate(chance = ifelse(description %in% chances, 1, 0))

# this step takes features for left handed pitchers only, that measure the x direction (horizontal movement/location)
# and flips their sign (i.e. negative values become positive.)
# This is done to make lefties' pitches look like righties' pitches to help the model train
# more accurately. (So a lefty slider and a righty slider will now look similar instead of opposite)
data <- sc %>%
  mutate(plate_x = ifelse(p_throws == "L", -1*plate_x, plate_x),
         pfx_x = ifelse(p_throws == "L", -1*pfx_x, pfx_x),
         release_pos_x = ifelse(p_throws == "L", -1*release_pos_x, release_pos_x))

# making/adjusting some features
# some categorical variables need to be changed to binary (0/1) to be handled by xgboost
data <- data %>%
  mutate(barrel = ifelse(is.na(barrel), 0, barrel),
         same_hand = ifelse(p_throws == stand, 1, 0),
         stand = ifelse(stand == "R", 1, 0),
         balls = ifelse(balls == 4, 3, balls),
         count = factor(str_c(as.character(balls), as.character(strikes), sep = "-")), # make a count variable
         pitch_type = case_when(
           pitch_type %in% c("FT", "FA") ~ "FF",
           TRUE ~ pitch_type), # combining a couple different fastball types
         pitch_type = factor(pitch_type))

# One Hot Encoding the count variable for xgboost
data <- one_hot(as.data.table(data), cols = "count")

##### MODEL BUILDING ###########################################################

# 75/25 train/valid split
train_size <- floor(0.75 * nrow(data))
set.seed(123)
train_ind <- sample(seq_len(nrow(data)), size = train_size) # get indices for rows in train

train <- data[train_ind, ]
valid <- data[-train_ind, ]

# What we want to do is train two models:
#   - A model that predicts the probability of a pitch being barrelled.
#   - A model that predicts the probablitiy of a pitch being swung at or called for a strike.


xgb_data <- train %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`,
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

# XGBOOST
# barrel model

barrel_label <- train$barrel

# I couldn't find any tuning method that meaningfully improved 

barrel_cv <- xgb.cv(data = as.matrix(xgb_data), label = barrel_label, nrounds = 350, nfold = 5,
                    early_stopping_rounds = 50, metrics = "logloss", eta = 0.1, objective = "binary:logistic")

eval_log <- as.data.frame(barrel_cv$evaluation_log)
nrounds_barrel <- which.min(eval_log$test_logloss_mean) # the number of rounds to use in model

barrel_mod <- xgboost(data = as.matrix(xgb_data), label = barrel_label, eta = 0.1,
                      nrounds = nrounds_barrel, objective = "binary:logistic")


xgb_valid <- valid %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`, 
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

# make preds on validation set
barrel_preds <- predict(barrel_mod, as.matrix(xgb_valid))

# get logloss
barrel_loss <- LogLoss(barrel_preds, valid$barrel)

data <- data %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`, 
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

# predict barrels on full data
full_barrel_preds <- predict(barrel_mod, as.matrix(data))

# put barrel probabilities into sc
sc$xBarrel <- full_barrel_preds

# Chance Model

chance_label <- train$chance

chance_cv <- xgb.cv(data = as.matrix(xgb_data), label = chance_label, nrounds = 275, nfold = 5, early_stopping_rounds = 50,
                    metrics = "logloss", eta = 0.1, objective = "binary:logistic")

# getting the proper number of model iterations to prevent under/overfitting
eval_log <- as.data.frame(chance_cv$evaluation_log)
nrounds_chance <- which.min(eval_log$test_logloss_mean)

# train chance model
chance_mod <- xgboost(data = as.matrix(xgb_data), label = chance_label,
                      eta = 0.1, nrounds = nrounds_chance, objective = "binary:logistic")


chance_preds <- predict(chance_mod, as.matrix(xgb_valid))
chance_loss <- LogLoss(chance_preds, valid$chance)
full_chance_preds <- predict(chance_mod, as.matrix(data))
sc$xChance <- full_chance_preds




# Feature Importance

# Compute feature importance matrix
barrel_importance <- xgb.importance(colnames(xgb_data), model = barrel_mod)
chance_importance <- xgb.importance(colnames(xgb_data), model = chance_mod)

# Nice graph for barrel importance
xgb.ggplot.importance(barrel_importance[1:10,]) +
  theme_bw() +
  theme(
    legend.position = "none"
  ) +
  labs(
    title = "Feature Importance for XGBoost Model Predicting Barrels"
  )

xgb.ggplot.importance(chance_importance[1:10,]) +
  theme_bw() +
  theme(
    legend.position = "none"
  ) +
  labs(
    title = "Feature Importance for XGBoost Model Predicting 'Chances'"
  )


##### PLOTS ####################################################################

# "mistakes" plot
sc %>%
  arrange(desc(xBarrel)) %>%
  mutate(pitch_name = ifelse(pitch_name == "Fastball", "4-Seam Fastball", pitch_name)) %>%
  filter(row_number() < (nrow(sc) * 0.015)) %>%
  ggplot(aes(plate_x, plate_z)) +
  geom_point(size = 4, alpha = 0.3, aes(color = stand)) +
  geom_segment(x = -5/6, y = 3.67, xend = -5/6 , yend = 1.52) + # draw strikezone
  geom_segment(x = 5/6, y = 3.67, xend = 5/6 , yend = 1.52) +
  geom_segment(x = -5/6, y = 3.67, xend = 5/6 , yend = 3.67) +
  geom_segment(x = -5/6, y = 1.52, xend = 5/6 , yend = 1.52) +
  coord_fixed() +
  theme_bw() +
  xlim(-1,1) +
  ylim(1.5,3.75) +
  facet_wrap(~pitch_name) +
  labs(
    title = "Mistake Pitches By Pitch Type",
    subtitle = "2021 MLB Season",
    x = "Horizontal Plate Location",
    y = "Vertical Plate Location"
  ) +
  scale_color_discrete(name = "Batter Side")
  


# barrels plot
sc %>%
  filter(barrel == 1) %>%
  ggplot(aes(plate_x, plate_z)) +
  geom_point(size = 4, alpha = 0.5, aes(color = stand)) +
  geom_segment(x = -5/6, y = 3.67, xend = -5/6 , yend = 1.52) + # draw strikezone
  geom_segment(x = 5/6, y = 3.67, xend = 5/6 , yend = 1.52) +
  geom_segment(x = -5/6, y = 3.67, xend = 5/6 , yend = 3.67) +
  geom_segment(x = -5/6, y = 1.52, xend = 5/6 , yend = 1.52) +
  coord_fixed() +
  theme_bw()

chadwick_player_lu_table <- get_chadwick_lu()

chadwick_player_lu_table <- chadwick_player_lu_table %>%
  select(name_first, name_last, key_mlbam)

####

p_barrels <- sc %>%
  group_by(pitcher, pitch_name) %>%
  summarize(pitches = n(),
            chances = sum(chance),
            barrels = sum(barrel, na.rm = TRUE),
            xbarrels = sum(xBarrel),
            xchances = sum(xChance),
            barrel_rate = barrels/pitches,
            xbarrel_rate = xbarrels / pitches,
            xbpc = xbarrels/xchances) %>%
  left_join(chadwick_player_lu_table, by = c("pitcher" = "key_mlbam")) %>%
  mutate(name = str_c(name_first, name_last, sep = " ")) %>%
  ungroup() %>%
  select(-pitcher, -name_first, -name_last)

p_barrels %>%
  filter(pitches > 500) %>%
  arrange(desc(xbpc)) %>%
  select(-barrel_rate, -xbarrel_rate) %>%
  select(name, everything()) %>%
  head(10) %>%
  gt() %>%
  tab_header(
    title = "Top 10 Mistake Prone Pitchers, 2021 MLB Season",
    subtitle = "1500 pitch min."
  ) %>%
  tab_options(
    heading.title.font.weight = "bold",
    table.width = px(700)
  ) %>%
  opt_row_striping() %>%
  cols_label(
    name = "Pitcher",
    pitch_name = "Pitch",
    pitches = "Pitches",
    chances = "Chances",
    barrels = "Barrels",
    xbarrels = "xBarrels (xB)",
    xchances = "xChances (xC)",
    xbpc = "xB/xC"
  ) %>%
  opt_align_table_header(align = "left") %>%
  fmt_number(columns = xbpc, decimals = 4) %>%
  fmt_number(columns = xbarrels, decimals = 2)
  
  
p_barrels %>%
  filter(pitches > 1500) %>%
  arrange(desc(chances - xchances))

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
  geom_rect(aes(xmin = -5/6, xmax = 5/6, ymin = 1.52, ymax = 3.67), color = "white", alpha = 0) +
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
  geom_rect(aes(xmin = -5/6, xmax = 5/6, ymin = 1.52, ymax = 3.67), color = "white", alpha = 0) +
  theme_bw() +
  coord_fixed() +
  labs(
    x = "Horizontal Pitch Location",
    y = "Vertical Pitch Location",
    title = "Barrel Rate (per pitch) by Pitch Location",
    subtitle = "(Catcher's Perspective)",
    fill = "Barrels/Pitch"
  )


# What percentage of bip are barrels?
# If I wanted to change my target from barrels to "barrels adjusted for batter," I would want to take the
# top X % of each batter's batted balls, where X is the percentage of total balls in play that are barrels 

sc %>%
  mutate(barrel = ifelse(is.na(barrel), 0, barrel)) %>%
  summarize(prop = sum(barrel, na.rm = TRUE)/n())
# About 7.5 % of all batted balls are barrels

sc %>%
  arrange(desc(xBarrel)) %>%
  filter(row_number() < (nrow(sc) * 0.015)) %>%
  arrange(xBarrel)

sc %>%
  filter(xBarrel >= 0.1) %>%
  arrange(xBarrel)

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


sc %>%
  filter(pitch_type == "FF" & zone == 5) %>%
  ggplot(aes(pfx_z, xBarrel)) +
    geom_point()

sc %>%
  filter(pitch_type == "FF" & zone == 5 & pfx_z < -0.5) %>%
  select(release_speed) %>%
  arrange(desc(release_speed))
