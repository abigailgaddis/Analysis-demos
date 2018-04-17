# Demo of CausalImpact library
# calculating causal impact from the difference in a time series due to an intervention

## Use it when you have a correlated control time series that should not be influenced by the intervention

# Making a randomly generated time series with a bump from 71:100

set.seed(4)
x1<- 100 + arima.sim(model = list(ar =0.999), n =100)
y<- 1.2 * x1 + rnorm(100)
y[71:100]<- y[71:100] +10
time.points <- seq.Date(as.Date("2018-01-01"), by = 1, length.out = 100)
data <- zoo(cbind(y, x1), time.points)

#Don't have to use dates at all - could just use x and y. Dates make the plots nice


#Has 100 rows and 2 columns
dim(data)
head(data)

#plotting the time series
matplot(data, type = "l")

#to use the Causal Impact suite, you need to specify the intervention period
#train period
pre.period<-as.Date(c("2018-01-01", "2018-03-11"))
#casual test period
post.period<-as.Date(c("2018-03-12", "2018-04-10"))
impact<- CausalImpact(data, pre.period, post.period)

#using built in plot function to show the effect of the intervention
plot(impact)

#panel 1 shows the data and conterfactual prediction for the posttreatment period
#panel 2 shows the difference between observed and counterfactual prediction
# this should be about zero until the period of interest
# panel 2 adds up the differences shown in panel 2 over time, the cumulative effect of the intervention

summary(impact)

#for multivariate data, plot the posterior probability of each predictor being included in the model
plot(impact$model$bsts.model, "coefficients")
