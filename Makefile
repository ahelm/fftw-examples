CC=gcc-8
FORTRAN=gfortran-8

C_COMPILE = -std=c99 -g
C_INCLUDE = -I $(shell brew --prefix fftw)/include
C_LINK	  = -L $(shell brew --prefix fftw)/lib -l fftw3 -l m

F_COMPILE = -std=f2003
F_INCLUDE = -I $(shell brew --prefix fftw)/include
F_LINK    = -L $(shell brew --prefix fftw)/lib -l fftw3 -l m

GNUPLOT=gnuplot
PYTHON=$(BASE_CONDA)/bin/python

.PHONY: all
all: plot-adv-interface plot-fftw-simple plot-fftw-fortran-c

.PHONY: clean
clean:
	@rm -rf bin/fftw-* *.mod adv_*.txt pre_*.txt fortran_*.txt

bin/fftw-simple: fftw-simple.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-simple fftw-simple.c

.PHONY: plot-fftw-simple
plot-fftw-simple: bin/fftw-simple
	@bin/fftw-simple 1> pre_fft.txt 2> post_fft.txt
	@$(PYTHON) plot_files.py pre_fft.txt post_fft.txt --title "Simple FFTW test"
	@rm pre_fft.txt post_fft.txt

bin/fftw-adv-interface: fftw-adv-interface.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-adv-interface fftw-adv-interface.c

.PHONY: plot-adv-interface
plot-adv-interface: bin/fftw-adv-interface
	@bin/fftw-adv-interface
	@$(PYTHON) plot_files.py adv_*.txt --title "Advance interface"
	@rm adv_*.txt

bin/fftw-fortran-c: fftw-fortran-c.f03
	$(FORTRAN) $(F_COMPILE) $(F_INCLUDE) $(F_LINK) -o bin/fftw-fortran-c fftw-fortran-c.f03

.PHONY: plot-fftw-fortran-c
plot-fftw-fortran-c: bin/fftw-fortran-c
	@bin/fftw-fortran-c
	@$(PYTHON) plot_files.py fortran_pre.txt fortran_post.txt \
		--title "Fortran interface"
	@rm fortran_*.txt