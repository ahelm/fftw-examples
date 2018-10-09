CC=gcc-8
INCLUDE=-I $(shell brew --prefix fftw)/include
LINK=-L $(shell brew --prefix fftw)/lib -l fftw3 -l m
GNUPLOT=gnuplot

.PHONY: run
run: bin/fftw-simple
	@echo ">> Running example: fftw-simple"
	@echo ""
	@bin/fftw-simple

.PHONY: clean
clean:
	@rm -rf bin/*

bin/fftw-simple: fftw-simple.c
	$(CC) $(INCLUDE) $(LINK) -o bin/fftw-simple fftw-simple.c

.PHONY: plot-fftw-simple
plot-fftw-simple: bin/fftw-simple
	@bin/fftw-simple 1> pre_fft.txt 2> post_fft.txt
	@gnuplot -p -e "\
		set xrange [1:512]; \
	  set yrange [-0.05:1.05]; \
		plot 'pre_fft.txt' u :1 w l, \
		     'pre_fft.txt' u :2 w l, \
				 'post_fft.txt' u :1 w l, \
				 'post_fft.txt' u :2 w l; \
	"
	@rm pre_fft.txt post_fft.txt