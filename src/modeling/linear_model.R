# Linear modeling script

## Baseline linear model
lmod = lm(num_fires_log ~ ., train_data)
summary(lmod)
#Get training error
y_train_pred = predict(lmod,train_x)
OLS_train_rmse <- rmse(y_train_pred,train_y)
#Get testing error
y_test_pred = predict(lmod,test_x)
OLS_test_rmse <- rmse(y_test_pred,test_y)

## AIC Stepwise Model
#AIC selection
lmod_AIC = step(lmod)
sumary(lmod_AIC)
#Get training error
y_train_pred = predict(lmod_AIC,train_x)
AIC_train_rmse <- rmse(y_train_pred,train_y)
#Get testing error
y_test_pred = predict(lmod_AIC,test_x)
AIC_test_rmse <- rmse(y_test_pred,test_y)

## Principal Component Regression
#PCR using cross-validation
modpcr = pcr(num_fires_log ~ .,data=train_data,ncomp=20,validation="CV",segments=10)
rmsCV = RMSEP(modpcr,estimate='CV')
which.min(rmsCV$val)
#Get training error
y_train_pred = predict(modpcr,train_x,ncomp=20)
PCR_train_rmse <- rmse(y_train_pred,train_y)
#Get testing error
y_test_pred = predict(modpcr,test_x,ncomp=20)
PCR_test_rmse <- rmse(y_test_pred,test_y)

## Ridge regression
grid = 10^seq(10, -2, length = 100)
ridge_mod = cv.glmnet(model.matrix(num_fires_log ~ ., train_data)[,-1],
                      train_y, alpha = 0, lambda = grid)
ridge_pred = predict(ridge_mod, s = ridge_mod$lambda.min,
                     newx = model.matrix(num_fires_log ~ ., test_data)[,-1])
Ridge_test_rmse <- rmse(ridge_pred,test_y)

## Lasso regression
grid = 10^seq(10, -2, length = 100)
lasso_mod = cv.glmnet(model.matrix(num_fires_log ~ ., train_data)[,-1],
                      train_y, alpha = 1, lambda = grid)
lasso_pred = predict(lasso_mod, s = lasso_mod$lambda.min,
                     newx = model.matrix(num_fires_log ~ ., test_data)[,-1])
Lasso_test_rmse <- rmse(lasso_pred,test_y)
