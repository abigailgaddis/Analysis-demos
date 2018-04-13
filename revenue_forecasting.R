library(tidyverse)
library(dplyr)
library(reshape)
library(lubridate)
library(data.table)
library(ggplot2)
library(prophet)

## Reading in sales data for forecasting
df_filepath = file.path("~","Work","ForeCasting","sales_by_month_and_plat.csv" )
df = data.frame(fread(df_filepath, na.strings = 'NULL'))
names(df) <- c("date","platform", "edition", "units_sold", "revenue")

## Doin some date math, all the cool kids do it
df$date <- ymd(paste0(as.character(df$date)))

## Pulling out pc/java, taking the log of the data to normalize it
df_java <- subset(df, platform == "PC/Java" & date >as.Date("2011-12-01"))
df_java$units_sold<-log(df_java$units_sold)
df_java$revenue<-log(df_java$revenue)

## Grabbing units sold and revenue separately to predict
df_java_units <- df_java[c("date","units_sold")]
df_java_revenue <- df_java[c("date","revenue")]

## Changing the namnes to work in Prophet
names(df_java_units) <- c("ds","y")
names(df_java_revenue) <- c("ds","y")

## Prophet - units sold
m <- prophet(df_java_units,changepoint.prior.scale = .005)
future <- make_future_dataframe(m, 90)
pred <- predict(m, future)
plot(m,pred)

## Prophet - revenue
m <- prophet(df_java_revenue,changepoint.prior.scale = .005)
future <- make_future_dataframe(m, 90)
pred <- predict(m, future)
plot(m,pred)
