# Random forest modeling script

set.seed(123)

# First model
rf_model <- randomForest(num_fires_log ~ ., data=train_data, 
                         importance=TRUE, proximity=TRUE)

# Get predictions
y_train_pred <- predict(rf_model, train_x)
y_test_pred <- predict(rf_model, test_x)

# Get RMSE of predictions
rf_train_rmse <- rmse(y_train_pred, train_y)
rf_test_rmse <- rmse(y_test_pred, test_y)

# Plot base model
#plot(rf_model)

# Use tuneRF to find optimal mtry
tune_train <- data.frame(train_data)
t <- tuneRF(tune_train[,setdiff(colnames(tune_train), "num_fires_log")],
            tune_train[,"num_fires_log"],
            stepFactor = 1.3,
            ntreeTry = 100,
            trace = TRUE,
            improve = 0.0,
            plot = FALSE)

# Plot treesize of base model
#hist(treesize(rf_model), main = "Number of Nodes for the Trees", col = "grey")

# Variable name changes
# To make VIP clearer
rownames(rf_model$importance)[11] <- "house_three_plus_generations_log"
rownames(rf_model$importance)[15] <- "total_population_white_log"
rownames(rf_model$importance)[17] <- "total_races_householders_log"

# Use caret random training to find best mtry
# Training takes a long time, so optimal mtry is hard coded
opt_mtry <- 11
if (!exists("opt_mtry")) {
  control <- trainControl(method='repeatedcv', 
                          number=4, 
                          repeats=2,
                          search = 'random',
                          verboseIter=TRUE)
  
  set.seed(123)
  rf_rand <- train(num_fires_log~., 
                    data=train_data, 
                    method='rf', 
                    metric='RMSE', 
                    tuneLength=10, 
                    trControl=control)
  plot(rf_rand)
}

# Create new model using optimal mtry
rf_model_opt <- randomForest(num_fires_log ~ ., data=train_data, mtry=opt_mtry, 
                          importance=TRUE, proximity=TRUE)

# Get predictions
y_train_pred_opt <- predict(rf_model_opt, train_x)
y_test_pred_opt <- predict(rf_model_opt, test_x)

# Get RMSE
rf_opt_train_rmse <- rmse(y_train_pred_opt, train_y)
rf_opt_test_rmse <- rmse(y_test_pred_opt, test_y)

# Variable Names changes 
# To make VIP clearer
rownames(rf_model_opt$importance)[11] <- "house_three_plus_generations_log"
rownames(rf_model_opt$importance)[15] <- "total_population_white_log"
rownames(rf_model_opt$importance)[17] <- "total_races_householders_log"
