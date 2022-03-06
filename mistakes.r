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

options(scipen = 999999)

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
# I also filter out the few observations that don't have location, pitch velo or release position data.
sc <- sc %>%
  filter(!(type == "X" & grepl(" bunt", des))) %>%
  filter(!(grepl("bunt", description))) %>%
  filter(!is.na(plate_x) | !is.na(release_speed) | !is.na(release_pos_z)) %>%
  mutate(chance = ifelse(description %in% chances, 1, 0))

sc %>%
  group_by(barrel) %>%
  mutate(barrel = ifelse(is.na(barrel), 0, barrel)) %>%
  summarize(n = n())

# 1.5 % of pitches are barrels.

# this step takes features that measure in the x direction (horizontal movement/location)
# and flips their sign (i.e. negative values become positive.)
# This is done to make lefties' pitches look like righties' pitches to help the model train
# more accurately.
data <- sc %>%
  mutate(plate_x = ifelse(p_throws == "L", -1*plate_x, plate_x),
         pfx_x = ifelse(p_throws == "L", -1*pfx_x, pfx_x),
         release_pos_x = ifelse(p_throws == "L", -1*release_pos_x, release_pos_x))



# making some features
data <- data %>%
  mutate(barrel = ifelse(is.na(barrel), 0, barrel),
         same_hand = ifelse(p_throws == stand, 1, 0),
         stand = ifelse(stand == "R", 1, 0),
         balls = ifelse(balls == 4, 3, balls),
         count = factor(str_c(as.character(balls), as.character(strikes), sep = "-")),
         pitch_type = case_when(
           pitch_type %in% c("FT", "FA") ~ "FF",
           TRUE ~ pitch_type),
         pitch_type = factor(pitch_type))

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

# Tuning

# grid <- grid_latin_hypercube(
#   # this finalize thing is because mtry depends on # of columns in data
#   finalize(mtry(), train),
#   min_n(),
#   tree_depth(),
#   # to force learn_rate to not be crazy small like dials defaults to
#   # because my computer is slow
#   # if you're trying this for a different problem, expand the range here
#   # by using more negative values
#   learn_rate(range = c(-1.5, -0.5), trans = log10_trans()),
#   loss_reduction(),
#   sample_size = sample_prop(),
#   size = 4
#   ) %>%
#   mutate(
#     # has to be between 0 and 1 for xgb
#     # for some reason mtry gives the number of columns rather than proportion
#     mtry = mtry / length(train),
#     # see note below
#   ) %>%
#   # make these the right names for xgb
#   dplyr::rename(
#     eta = learn_rate,
#     gamma = loss_reduction,
#     subsample = sample_size,
#     colsample_bytree = mtry,
#     max_depth = tree_depth,
#     min_child_weight = min_n
#   )
# 
# grid
# 

xgb_data <- train %>%
  select(release_speed, same_hand, stand, plate_x, plate_z, pfx_x, pfx_z, release_pos_x, release_pos_z,
         `count_0-0`, `count_1-0`, `count_2-0`, `count_3-0`,
         `count_0-1`, `count_1-1`, `count_2-1`, `count_3-1`,
         `count_0-2`, `count_1-2`, `count_2-2`, `count_3-2`)

# 
# # function to perform xgb.cv for a given row in a hyperparameter grid
# get_row <- function(row) {
#   params <-
#     list(
#       booster = "gbtree",
#       objective = "binary:logistic",
#       eval_metric = c("logloss"),
#       eta = row$eta,
#       gamma = row$gamma,
#       subsample = row$subsample,
#       colsample_bytree = row$colsample_bytree,
#       max_depth = row$max_depth,
#       min_child_weight = row$min_child_weight
#     )
# 
#   # do the cross validation
#   wp_cv_model <- xgb.cv(
#     data = as.matrix(xgb_data),
#     label = train$barrel,
#     params = params,
#     # this doesn't matter with early stopping in xgb.cv, just set a big number
#     # the actual optimal rounds will be found in this tuning process
#     nrounds = 15000,
#     metrics = list("logloss"),
#     early_stopping_rounds = 50,
#     print_every_n = 50,
#     nfold = 5
#   )
# 
#   # bundle up the results together for returning
#   output <- params
#   output$iter <- wp_cv_model$best_iteration
#   output$logloss <- wp_cv_model$evaluation_log[output$iter]$test_logloss_mean
# 
#   row_result <- bind_rows(output)
# 
#   return(row_result)
# }
# 
# start_time <- Sys.time()
# 
# # get results
# results <- purrr::map_df(1:nrow(grid), function(x) {
#   get_row(grid %>% dplyr::slice(x))
# })
# 
# end_time <- Sys.time()
# 
# 
# 
# best_model <- results %>%
#   dplyr::arrange(logloss) %>%
#   dplyr::slice(1)
# 
# params <-
#   list(
#     booster = "gbtree",
#     eval_metric = c("logloss"),
#     eta = best_model$eta,
#     gamma = best_model$gamma,
#     subsample = best_model$subsample,
#     colsample_bytree = best_model$colsample_bytree,
#     max_depth = best_model$max_depth,
#     min_child_weight = best_model$min_child_weight
#   )
# 
# nrounds_barrel <- best_model$iter
# 
# params

# XGBOOST
# barrel model

barrel_label <- train$barrel

barrel_cv <- xgb.cv(data = as.matrix(xgb_data), label = barrel_label, nrounds = 150, nfold = 5,
                    early_stopping_rounds = 50, metrics = "logloss", eta = 0.1, objective = "binary:logistic")

eval_log <- as.data.frame(barrel_cv$evaluation_log)
nrounds_barrel <- which.min(eval_log$test_logloss_mean)

barrel_mod <- xgboost(data = as.matrix(xgb_data), label = barrel_label, eta = 0.1,
                      nrounds = nrounds_barrel, objective = "binary:logistic")


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

chance_cv <- xgb.cv(data = as.matrix(xgb_data), label = chance_label, nrounds = 175, nfold = 5,
                    metrics = "logloss", eta = 0.1, objective = "binary:logistic")

# getting the proper number of model iterations to prevent under/overfitting
eval_log <- as.data.frame(chance_cv$evaluation_log)
nrounds_chance <- which.min(eval_log$test_logloss_mean)
#nrounds_chance <- 136

# train models
chance_mod <- xgboost(data = as.matrix(xgb_data), label = chance_label,
                      eta = 0.1, nrounds = nrounds_chance, objective = "binary:logistic")


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

xgb.ggplot.importance(chance_importance[1:10,]) +
  theme_bw() +
  theme(
    legend.position = "none"
  ) +
  labs(
    title = "Feature Importance for XGBoost Model Predicting 'Chances'"
  )

full_chance_preds <- predict(chance_mod, as.matrix(data))

sc$xChance <- full_chance_preds

mistake_thresh <- 0.1



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
  left_join(chadwick_player_lu_table, by = c("pitcher" = "key_mlbam")) %>%
  mutate(name = str_c(name_first, name_last, sep = " ")) %>%
  select(-pitcher, -name_first, -name_last)

p_barrels %>%
  filter(pitches > 1500) %>%
  arrange(desc(xbpc)) %>%
  select(-mistakes, -barrel_rate, -xbarrel_rate) %>%
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
