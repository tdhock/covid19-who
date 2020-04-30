TODAY_CSV=wikipedia/$(shell date +%Y-%m-%d).csv
wikipedia-population-analyze.png: wikipedia-population-analyze.R ${TODAY_CSV}
	R --vanilla < $<
wikipedia-analyze.png: wikipedia-analyze.R ${TODAY_CSV}
	R --vanilla < $<
${TODAY_CSV}: wikipedia-download.R
	R --vanilla < $<
	git add wikipedia/*
