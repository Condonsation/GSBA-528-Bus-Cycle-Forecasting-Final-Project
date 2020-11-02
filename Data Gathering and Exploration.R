library(readr)
library(dplyr)
library(ggplot2)

US_Quarterly_GDP_ <- read_csv("US Quarterly GDP .csv")
Quarterly_domestic_average_fare <- read_csv("Quarterly national level domestic average fare series 2Q 2020 revised (1).csv")
Long_Term_Government_Bond_Yields <- read_csv("Long-Term Government Bond Yields.csv")

##Get three dfs to have same length of time (1995-2020Q2)
US_Quarterly_GDP_ <- US_Quarterly_GDP_[193:294,]
Long_Term_Government_Bond_Yields <- Long_Term_Government_Bond_Yields[1:102,]

Master_df <- cbind(Quarterly_domestic_average_fare, US_Quarterly_GDP_, Long_Term_Government_Bond_Yields)[ , -c(5, 7)]    
Master_df <- rename(Master_df, "Long_Term_Gov_Bond_Yields" = "Long-Term_Gov_Bond_Yields") ##Rename Bond Yields column header to avoid confusion
Master_df <- rename(Master_df, "US_Average_Fare" = "US_Average(Current)") ##Rename avg. fare column header to avoid confusion
Master_df$YearQrt <- paste(Master_df$Year, Master_df$Quarter, sep = 'Q')

summary(Master_df) ##summary stats

write.csv(Master_df, "Master_df.csv")

##Visualization
ggplot(Master_df, aes(YearQrt, GDP)) +
  geom_point(size=1, color = "blue") + geom_smooth()

ggplot(Master_df, aes(YearQrt, US_Average_Fare)) +
  geom_point(size=1, color = "Red") + geom_smooth()

ggplot(Master_df, aes(YearQrt, Long_Term_Gov_Bond_Yields)) +
  geom_point() + geom_line(size=.75) + geom_smooth()

cor(Master_df[,3:6]) ##correlation table: all three vars have strong corr
