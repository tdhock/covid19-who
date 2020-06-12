csv.vec <- Sys.glob("cdc-states/*.csv")
recent.csv <- csv.vec[length(csv.vec)]

states.dt <- data.table::fread(recent.csv)
states.dt[, .(
  count=.N,
  sum=sum(`COVID-19 Deaths`, na.rm=TRUE)
), by=State][order(sum)]

states.dt[, week.POSIXct := suppressWarnings({
  strptime(`Start week`, "%m/%d/%Y")
})]
states.dt[, .(`Start week`, week.POSIXct)]
names(states.dt)
only.states <- states.dt[!State %in% c("United States", "New York City")]
library(ggplot2)
ggplot()+
  geom_line(aes(
    week.POSIXct, `COVID-19 Deaths`,
    color=State),
    data=only.states)+
  scale_y_log10()
