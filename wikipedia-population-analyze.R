source("packages.R")
Sys.setlocale(locale="C")

out.csv.vec <- Sys.glob("wikipedia/*.csv")

out.csv <- out.csv.vec[length(out.csv.vec)]
count.dt <- data.table::fread(out.csv)
count.dt[, date.POSIXct := as.POSIXct(date.POSIXct)]

pop.dt <- data.table::fread("population-download.csv")[count.dt, on="country"]
pop.dt[, cum.deaths.per.capita := cum.deaths/population]
pop.dt[, cum.deaths.per.million := cum.deaths.per.capita*1e6]
most.recent <- pop.dt[
  is.finite(cum.deaths.per.capita), .SD[which.max(date.POSIXct)], by=country]
per.cap.rank <- most.recent[order(cum.deaths.per.capita)]
per.cap.rank[, percentile := (1:.N)/.N]
my.countries <- c(
  "France", "Japan", "Canada", "USA", "Switzerland", "Austria")
more.countries <- c("China", "India", "Brazil")
show.countries <- my.countries
some.rank <- per.cap.rank[show.countries, on="country"]
some.rank[, pop.M := population/1e6]
some.rank[, country.info := sprintf(
  "%s\npop=%.1fM\n%d deaths\n%.1f per M",
  country, pop.M,
  cum.deaths,
  cum.deaths.per.million)]
some.rank[, cum.deaths.info := sprintf(
  "%s\n%d deaths",
  country, 
  cum.deaths)]
some.rank[, cum.deaths.per.million.info := sprintf(
  "%s pop=%.1fM\n%.1f deaths per M",
  country,
  pop.M,
  cum.deaths.per.million)]
some.dt <- pop.dt[some.rank, on="country"]
some.range <- range(some.dt$date.POSIXct)
xmax <- some.range[2]+(some.range[2]-some.range[1])*0.2
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, cum.deaths.per.million, color=country.info),
    data=some.dt)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")
directlabels::direct.label(gg, "last.polygons")
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, cum.deaths.per.million, color=country.info),
    data=some.dt)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")+
  scale_y_log10()
dl <- directlabels::direct.label(gg, "last.polygons")
print(dl)
both.dt.list <- list()
for(variable in c("cum.deaths", "cum.deaths.per.million")){
  v.info <- paste0(variable, ".info")
  info.dt <- some.rank[, c("country", v.info), with=FALSE]
  setnames(info.dt, c("country", "label"))
  v.count.dt <- some.dt[
    info.dt,
    c(variable, "country", "date.POSIXct", "label"),
    with=FALSE,
    on="country"]
  names(v.count.dt)[1] <- "value"
  both.dt.list[[variable]] <- data.table(
    variable, v.count.dt)
}
both.dt <- do.call(rbind, both.dt.list)
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, value, color=country),
    data=both.dt)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  theme_bw()+
  theme(legend.position="none", panel.spacing=grid::unit(0, "lines"))+
  facet_grid(variable ~ ., scales="free")+
  scale_x_datetime(
    "Date",
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")+
  scale_y_log10("")+
  directlabels::geom_dl(aes(
    date.POSIXct, value, color=country, label=label),
    data=both.dt,
    method="last.polygons")+
  ggtitle(paste(
    "Cumulative death counts and rates due to COVID19,",
    "source: WHO/wikipedia"))
print(gg)
width <- 10
height <- 8
png(
  "wikipedia-population-analyze-cum.png",
  width=width, height=height, units="in", res=100)
print(gg)
dev.off()

new.dt <- some.dt[order(date.POSIXct), .(
  cum.deaths,
  new.deaths=c(cum.deaths[1], diff(cum.deaths)),
  date.POSIXct
), by=.(country, population)]
new.dt[, new.deaths.per.capita := new.deaths/population]
new.dt[, new.deaths.per.million := new.deaths.per.capita*1e6]
new.dt[, day := strftime(date.POSIXct, "%a")]
one.day <- new.dt[day=="Sun"]
gg <- ggplot()+
  geom_line(aes(
    date.POSIXct, new.deaths.per.million, color=country),
    data=new.dt)+
  geom_point(aes(
    date.POSIXct, new.deaths.per.million, color=country, shape=day),
    data=one.day)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")
print(gg)

dl <- directlabels::direct.label(gg, "last.polygons")
dl.log <- dl+scale_y_log10()

new.tall <- melt(
  new.dt, measure.vars=c("new.deaths", "new.deaths.per.million"))

gg <- ggplot()+
  ggtitle(
    "Death counts/rates per day due to COVID19, source: WHO/wikipedia")+
  geom_line(aes(
    date.POSIXct, value, color=country),
    data=new.tall)+
  coord_cartesian(xlim=c(some.range[1], xmax))+
  scale_x_datetime(
    "Date",
    breaks=seq(some.range[1], some.range[2], l=5),
    date_labels="%d %b")+
  theme_bw()+
  scale_y_log10("")+
  theme(panel.spacing=grid::unit(0, "lines"))+
  facet_grid(variable ~ ., scales="free")
dl <- directlabels::direct.label(gg, "last.polygons")
print(dl)

png(
  "wikipedia-population-analyze.png",
  width=width, height=height, units="in", res=100)
print(dl)
dev.off()

