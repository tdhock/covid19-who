source("packages.R")

out.csv.vec <- Sys.glob("wikipedia/*.csv")

out.csv <- out.csv.vec[length(out.csv.vec)]
count.dt <- data.table::fread(out.csv)
count.dt[, date.POSIXct := as.POSIXct(date.POSIXct)]
my.countries <- c(
  "France", "Japan", "Canada", "USA")
more.countries <- c("China", "India", "Brazil")
show.countries <- my.countries
some.dt <- count.dt[country %in% show.countries]
some.range <- range(some.dt$date.POSIXct)
xmax <- some.range[2]+(some.range[2]-some.range[1])*0.15
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, cum.deaths, color=country),
    data=some.dt)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(breaks=seq(some.range[1], some.range[2], l=5))
directlabels::direct.label(gg, "last.polygons")

gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, cum.deaths, color=country),
    data=some.dt)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(breaks=seq(some.range[1], some.range[2], l=5))+
  scale_y_log10()
directlabels::direct.label(gg, "last.polygons")

new.dt <- some.dt[order(date.POSIXct), .(
  new.deaths=c(cum.deaths[1], diff(cum.deaths)),
  date.POSIXct
), by=country]

Sys.setlocale(locale="C")
new.dt[, day := strftime(date.POSIXct, "%a")]
one.day <- new.dt[day=="Sun"]
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, new.deaths, color=country),
    data=new.dt)+
  geom_point(aes(
    date.POSIXct, new.deaths, color=country, shape=day),
    data=one.day)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")
dl <- directlabels::direct.label(gg, "last.polygons")
dl.log <- dl+scale_y_log10()
png("wikipedia-analyze.png", width=10, height=6, units="in", res=100)
print(dl.log)
dev.off()

