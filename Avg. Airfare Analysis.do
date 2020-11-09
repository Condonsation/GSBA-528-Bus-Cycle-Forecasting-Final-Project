*Get date into correct quarterly format
gen qdate = quarterly(yearqrt, "YQ")
format qdate %tq

*Set time series
tsset qdate 

*Create line graphs
tsline gdp, title(Gross Domestic Product) //clear upward trend
tsline us_average_fare, title(Domestic Average Airline Fare) //possible multaplicative trend
tsline long_term_gov_bond_yields, title(Long-Term Government Bond Yields: 10-year) //downward additive trend

*Look at distributions
hist gdp, freq kdensity
gen ln_gdp=ln(gdp)
hist ln_gdp, freq kdensity normopts(lcolor(blue))

hist us_average_fare, freq kdensity
sktest us_average_fare //cannot reject null

hist long_term_gov_bond_yields, freq kdensity

*Make stationary
corrgram gdp, lags(20) //there is SC and AC
ac gdp, title(Autocorrelation of GDP)
pac gdp, title(Autocorrelation of GDP)

varsoc gdp
dfuller gdp, trend lags(20) reg
dfuller gdp, trend lags(4) reg //nonstationary

varsoc d.gdp
dfuller d2.gdp, trend lags(0) reg 
dfuller d.ln_air, lags(4) reg 
**Can't make stationay??

*use %change in gpd
gen return=(price-l.price)/l.price

corrgram us_average_fare, lags(20)
varsoc us_average_fare
dfuller us_average_fare, trend lags(1) reg
dfuller us_average_fare, trend lags(2) reg
dfuller us_average_fare, trend lags(3) reg //nonstationary
dfuller us_average_fare, trend lags(7) reg 

corrgram us_average_fare, lags(20) //there is SC and AC
ac us_average_fare, title(Autocorrelation of Average Domestic Airline Fare)
pac us_average_fare, title(Autocorrelation of Average Domestic Airline Fare)
varsoc d.us_average_fare
dfuller d.us_average_fare, trend lags(0) reg //stationary

//Build airfare in-sample models
*model 1
arima us_average_fare, arima(1,1,1)sarima(1,1,1,4) noconst nolog
estimates store model1

*model2
arima us_average_fare, arima(0,1,1)
estimates store model2

*model3
arima us_average_fare, arima(0,1,2)
estimates store model3

*model4
arima us_average_fare, arima(0,1,0)
estimates store model4

estimates table model1 model2 model3 model4, stat(aic bic) //model1 has smallest AIC and bic
lrtest model2 model1, stat 

arima us_average_fare, arima(1,1,1)sarima(1,1,1,4) noconst nolog
predict r, resid
tsline r, yline(0) title(TS plot of residual) //white noise pattern (good; random pattern)
corrgram r, lags(20)
wntestq r

**Generate predictions in new column
arima us_average_fare, arima(1,1,1)sarima(1,1,1,4) noconst nolog
predict y1, y dynamic(tm(2020q2))

label var y1 "Model 1: arima(1,1,1)sarima(1,1,1,4)"
**Graph in-sample prediction
tsline us_average_fare y1, lpattern(solid dash)lcolor(blue green)lwidth(medthink)title(Actual vs. In-Sample Forecast)ytitle(us_average_fare)

**Forecast forward
set obs 106
gen t=_n
tsset t

arima us_average_fare, arima(1,1,1)sarima(1,1,1,4) noconst nolog
predict f_y, y dynamic(103) //start at row 103
label var f_y "Forecast -Model 2: arima(1,1,1)sarima(1,1,1,4)"

tsline us_average_fare f_y, lpattern(solid dash)lcolor(blue green)lwidth(medthink)title(Actual vs. Forecast)ytitle(us_average_fare)

**Alternative models
tsset qdate
tssmooth ma s1=us_average_fare, window(2 1 2) replace //uniform weights
tssmooth ma s2=us_average_fare, weights(1 2 <3> 2 1) replace //nonuniform weights


tssmooth exponential s3=us_average_fare, forecast(4) replace //Exponential smoothing

tssmooth shwinters s4=us_average_fare, forecast(8) replace //Holt-Winters

tsline us_average_fare f_y s2, lcolor(maroon)lpatter(solid shortdash)lcolor(blue)title(Actual vs Various Smoothing Techniques)

forvalues i=1/4 {

gen noise`i' = s`i' - us_average_fare
gen noisesq`i' = (noise`i')^2
egen sum_noise`i' = sum(noisesq`i')
gen mse`i' = sum_noise`i'/_N

}

sum mse*

corrgram long_term_gov_bond_yields, lags(20)
varsoc long_term_gov_bond_yields
dfuller long_term_gov_bond_yields, trend lags(2) reg
dfuller long_term_gov_bond_yields, trend lags(3) reg
dfuller long_term_gov_bond_yields, trend lags(4) reg
dfuller long_term_gov_bond_yields, trend lags(5) reg //stationary

varsoc d.long_term_gov_bond_yields
dfuller d.long_term_gov_bond_yields, trend lags(0) reg

**Possible syntax for multivariate time series model
arima y x1 x2, arima(p,d,q)

*VAR modeling
gen changegdp=(gdp-l.gdp)/l.gdp
hist changegdp, freq kdensity
hist long_term_gov_bond_yields, freq kdensity
hist ln_gdp, freq kdensity

varsoc us_average_fare  changegdp, maxlag(7)
vecrank us_average_fare  changegdp, trend(constant) lags(5) max //Johansen cointegration test.  if there is a correlation between several time series in the long term. null hypothesis cannot be rejected. There is no cointegration
var us_average_fare  changegdp, lags(1/5)

var us_average_fare  changegdp, lags(1/5)
predict var1

var us_average_fare  changegdp, lags(1/5)
predict rvar, resid
tsline rvar, yline(0) title(TS plot of residual) //white noise pattern (good; random pattern)
corrgram rvar, lags(10)
wntestq rvar

var us_average_fare  changegdp, lags(1)
predict var2

tsline us_average_fare var1, lcolor(maroon)lpatter(solid shortdash)title(Actual vs VAR)

tsline us_average_fare var2, lcolor(maroon)lpatter(solid shortdash)title(Actual vs VAR)