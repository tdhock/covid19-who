source("packages.R")
Sys.setlocale(locale="C")

out.csv.vec <- Sys.glob("wikipedia/*.csv")

out.csv <- out.csv.vec[length(out.csv.vec)]
count.dt <- data.table::fread(out.csv)
count.dt[, date.POSIXct := as.POSIXct(date.POSIXct)]

orig.pop.dt <- data.table::fread(
  "population-download.csv"
)[count.dt, on="country"][order(country, -date.POSIXct)]
orig.pop.dt[, original := cum.deaths]
orig.pop.dt[, corrected := cummin(original), by=country]
orig.pop.dt[, was.corrected := original != corrected]
pop.dt <- melt(
  orig.pop.dt,
  measure.vars=c("original", "corrected"),
  id.vars=c("country", "population", "date.POSIXct", "was.corrected"),
  variable.name="data.type",
  value.name="cum.deaths")
pop.dt[, cum.deaths.per.capita := cum.deaths/population]
pop.dt[, cum.deaths.per.million := cum.deaths.per.capita*1e6]
most.recent <- pop.dt[
  is.finite(cum.deaths.per.capita), .SD[which.max(date.POSIXct)], by=country]
per.cap.rank <- most.recent[order(cum.deaths.per.capita)]
per.cap.rank[, percentile := (1:.N)/.N]
my.countries <- c(
  "France", "Japan", "Canada", "USA")
country.list <- list(
  "countries where I have lived"=my.countries,
  "selected countries"=c(
    my.countries,
    "China", "India", "Brazil", "Switzerland", "Austria"))
for(countries.i in seq_along(country.list)){
  show.countries <- country.list[[countries.i]]
  title.paren <- names(country.list)[[countries.i]]
  suffix <- if(countries.i==1)"" else paste0("-", gsub(" ", "-", title.paren))
  some.rank <- per.cap.rank[show.countries, on="country"]
  some.rank[, pop.M := population/1e6]
  some.rank[, `:=`(
    country.info=sprintf(
      "%s\npop=%.1fM\n%d deaths\n%.1f per M",
      country, pop.M,
      cum.deaths,
      cum.deaths.per.million),
    cum.deaths.info=sprintf(
      "%s\n%d deaths",
      country, 
      cum.deaths),
    cum.deaths.per.million.info=sprintf(
      "%s pop=%.1fM\n%.1f deaths per M",
      country,
      pop.M,
      cum.deaths.per.million))]
  some.info.cols <- c(
    "country",
    grep("info$", names(some.rank), value=TRUE))
  some.info <- some.rank[, ..some.info.cols]
  some.dt <- pop.dt[some.info, on="country"]
  some.range <- range(some.dt$date.POSIXct)
  xmax <- some.range[2]+(some.range[2]-some.range[1])*0.2
  ggplot()+
    geom_line(aes(
      date.POSIXct, cum.deaths.per.million,
      color=country.info,
      linetype=data.type),
      data=some.dt)+
    scale_linetype_manual(values=c(
      original="dotted",
      corrected="solid"))+
    coord_cartesian(xlim=c(some.range[1], xmax))+
    scale_x_datetime(
      breaks=seq(some.range[1], some.range[2], l=5),
      date_labels="%d %b")
  ggplot()+
    geom_line(aes(
      date.POSIXct, cum.deaths.per.million,
      color=country.info,
      linetype=data.type),
      data=some.dt)+
    scale_linetype_manual(values=c(
      original="dotted",
      corrected="solid"))+
    coord_cartesian(xlim=c(some.range[1], xmax))+
    scale_x_datetime(
      breaks=seq(some.range[1], some.range[2], l=5),
      date_labels="%d %b")+
    scale_y_log10()
  both.dt.list <- list()
  for(variable in c("cum.deaths", "cum.deaths.per.million")){
    v.info <- paste0(variable, ".info")
    info.dt <- some.rank[, c("country", v.info), with=FALSE]
    setnames(info.dt, c("country", "label"))
    v.cols <- c(
      variable, "country", "date.POSIXct", "label", "data.type",
      "was.corrected")
    v.count.dt <- some.dt[
      info.dt,
      v.cols,
      with=FALSE,
      on="country"]
    names(v.count.dt)[1] <- "value"
    both.dt.list[[variable]] <- data.table(
      variable, v.count.dt)
  }
  both.dt <- do.call(rbind, both.dt.list)
  diff.dt <- both.dt[was.corrected==TRUE & data.type=="original"]
  my.method <- list(cex=0.7, "last.polygons")
  gg <- ggplot()+
    ggtitle(paste0(
      "Cumulative death counts and rates due to COVID19, ",
      "source: WHO/wikipedia (",
      title.paren, ")"))+
    scale_linetype_manual(values=c(
      original="dotted",
      corrected="solid"))+
    geom_line(aes(
      date.POSIXct, value,
      color=country,
      linetype=data.type),
      data=both.dt)+
    geom_point(aes(
      date.POSIXct, value,
      color=country,
      shape=data.type),
      data=diff.dt)+
    scale_shape_manual(values=c(
      original=1))+
    coord_cartesian(xlim=c(some.range[1], xmax))+
    theme_bw()+
    theme(panel.spacing=grid::unit(0, "lines"))+
    facet_grid(variable ~ ., scales="free")+
    scale_x_datetime(
      "Date",
      breaks=seq(some.range[1], some.range[2], l=5),
      date_labels="%d %b")+
    scale_y_log10("")+
    scale_color_discrete(guide="none")+
    directlabels::geom_dl(aes(
      date.POSIXct, value, color=country, label=label),
      data=both.dt[data.type=="corrected"],
      method=my.method)
  print(gg)
  width <- 10
  height <- 8
  cum.png <- paste0(
    "wikipedia-population-analyze-cum",
    suffix,
    ".png")
  png(
    cum.png,
    width=width, height=height, units="in", res=100)
  print(gg)
  dev.off()
  new.dt <- some.dt[data.type=="corrected"][order(date.POSIXct), .(
    was.corrected,
    cum.deaths,
    new.deaths=c(cum.deaths[1], diff(cum.deaths)),
    date.POSIXct
  ), by=.(country, population)]
  new.dt[, new.deaths.per.capita := new.deaths/population]
  new.dt[, new.deaths.per.million := new.deaths.per.capita*1e6]
  new.dt[, day := strftime(date.POSIXct, "%a")]
  one.day <- new.dt[day=="Sun"]
  ggplot()+
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
  new.tall <- melt(
    new.dt, measure.vars=c("new.deaths", "new.deaths.per.million"))
  corrected.dt <- new.tall[was.corrected==TRUE]
  gg <- ggplot()+
    ggtitle(paste0(
      "Death counts/rates per day due to COVID19, ",
      "source: WHO/wikipedia (",
      title.paren, ")"))+
    geom_line(aes(
      date.POSIXct, value, color=country),
      data=new.tall)+
    geom_point(aes(
      date.POSIXct, value,
      color=country,
      shape=was.corrected),
      data=corrected.dt)+
    scale_shape_manual(values=c(
      "TRUE"=1))+
    coord_cartesian(xlim=c(some.range[1], xmax))+
    scale_x_datetime(
      "Date",
      breaks=seq(some.range[1], some.range[2], l=5),
      date_labels="%d %b")+
    theme_bw()+
    scale_y_log10("")+
    theme(panel.spacing=grid::unit(0, "lines"))+
    facet_grid(variable ~ ., scales="free")
  dl <- directlabels::direct.label(gg, my.method)
  print(dl)
  rate.png <- paste0(
    "wikipedia-population-analyze",
    suffix,
    ".png")
  png(
    rate.png,
    width=width, height=height, units="in", res=100)
  print(dl)
  dev.off()
}
