# Building risk analysis model on `mod_df` created in
# exploratory_data_analysis.Rmd

source("src/environment_setup/imports_options_constants.R")
source("src/environment_setup/helper_funcs.R")
source("src/data_collection_and_cleaning/reading_and_cleaning_data.R")

# Re-creating mod_df, as created in exploratory_data_analysis.Rmd
# Transforming specified variables to bring all predictors and response to a
# roughly symmetric distribution
vars_to_log_transform <- c("num_fires",
                           "number_of_households",
                           "population",
                           "total_18_years_and_over",
                           "total_family_households",
                           "total_household_has_three_or_more_generations",
                           "total_male",
                           "total_owner_occupied",
                           "total_population_of_one_race",
                           "total_population_of_one_race_white_alone",
                           "total_races_tallied",
                           "total_races_tallied_for_householders",
                           "total_renter_occupied",
                           "total_two_or_more_races",
                           "total_under_18_years")

# mod_df is the final modeling dataframe
mod_df <- mod_df_pre_eda %>%
    mutate(across(all_of(vars_to_log_transform),
                  function(col) log10(col + 1),
                  .names = "{.col}_log")) %>%
    select(-all_of(vars_to_log_transform))


# Creating train-test split
set.seed(177122745)
train_rows <- sample(1:nrow(mod_df), floor(nrow(mod_df) * .8), replace = FALSE)
test_rows <- setdiff(1:nrow(mod_df), train_rows)

train_data <- mod_df %>%
    filter(row_number() %in% train_rows) %>%
    select(-geoid)
test_data <- mod_df %>%
    filter(row_number() %in% test_rows)  %>%
    select(-geoid)

train_x <- train_data %>%
    select(-num_fires_log)
train_y <- train_data$num_fires_log

test_x <- test_data %>%
    select(-num_fires_log)
test_y <- test_data$num_fires_log


# Function for calculating rmse
rmse = function(x,y) {sqrt(mean((x-y)^2))}

# Runs the modeling scripts
source("src/modeling/linear_model.R")
# RF script might take a minute
source("src/modeling/random_forest.R")

# Commbine all model results into 1 dataframe 
models <- c("OLS", "AIC", "PCR", "Ridge", "Lasso", 
            "Random Forest", "Optimal Random Forest")
train_rmse <- c(OLS_train_rmse, AIC_train_rmse, PCR_train_rmse, NA, NA, 
                rf_train_rmse, rf_opt_train_rmse)
test_rmse <- c(OLS_test_rmse, AIC_test_rmse, PCR_test_rmse, Ridge_test_rmse, 
               Lasso_test_rmse, rf_test_rmse, rf_opt_test_rmse)

results <- data.frame(models, train_rmse, test_rmse)
results

# RF Base Plots
varImpPlot(rf_model, type = 1, n.var = 10, main = "MSE Increase Variable Importance")
varImpPlot(rf_model, type = 2, n.var = 10, main = "Gini Index Variable Importance")

# RF Opt Plots
varImpPlot(rf_model_opt, type = 1, n.var = 10, main = "MSE Increase Variable Importance")
varImpPlot(rf_model_opt, type = 2, n.var = 10, main = "Gini Index Variable Importance")

# Multi-Dimension Scaling Plot
MDSplot(rf_model_opt, train_data$num_fires_log, main="Multi-Dimensional Scaling Plot")



