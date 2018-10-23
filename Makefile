CC=gcc-8
FORTRAN=gfortran-8

C_COMPILE = -std=c99 -O3
C_INCLUDE = -I $(shell brew --prefix fftw)/include
C_LINK	  = -L $(shell brew --prefix fftw)/lib -l fftw3 -l m

F_COMPILE = -std=f2003
F_INCLUDE = -I $(shell brew --prefix fftw)/include
F_LINK    = -L $(shell brew --prefix fftw)/lib -l fftw3 -l m

GNUPLOT=gnuplot
PYTHON=$(BASE_CONDA)/bin/python

.PHONY: all
all: plot-fftw-simple plot-adv-interface-c plot-adv-interface-fortran

.PHONY: clean
clean:
	@rm -rf bin/fftw-* *.mod adv_*.txt pre_*.txt fortran_*.txt fftw_simple_*.raw benchmark/vector_transform_*.txt

bin/fftw-simple: fftw-simple.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-simple fftw-simple.c

.PHONY: plot-fftw-simple
plot-fftw-simple: bin/fftw-simple
	@bin/fftw-simple 1> pre_fft.txt 2> post_fft.txt
	@$(PYTHON) plot_files.py pre_fft.txt post_fft.txt --title "Simple FFTW test"
	@rm pre_fft.txt post_fft.txt

bin/fftw-adv-interface-c: fftw-adv-interface-c.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-adv-interface-c fftw-adv-interface-c.c

.PHONY: plot-adv-interface-c
plot-adv-interface-c: bin/fftw-adv-interface-c
	@bin/fftw-adv-interface-c
	@$(PYTHON) plot_files.py adv_pre.txt \
		--diff adv_post.txt \
		--marker "x" \
		--linestyle "none" \
		--title "Advance interface (Diff)"
	@rm adv_*.txt

bin/fftw-adv-interface-fortran: fftw-adv-interface-fortran.f03
	$(FORTRAN) $(F_COMPILE) $(F_INCLUDE) $(F_LINK) -o bin/fftw-adv-interface-fortran fftw-adv-interface-fortran.f03

.PHONY: plot-adv-interface-fortran
plot-adv-interface-fortran: bin/fftw-adv-interface-fortran
	@bin/fftw-adv-interface-fortran
	@$(PYTHON) plot_files.py fortran_pre.txt \
		--diff fortran_post.txt \
		--marker "x" \
		--linestyle "none" \
		--title "Fortran interface (Diff)"
	@rm fortran_*.txt

bin/fftw-benchmark-direct-vecArray: fftw-benchmark-direct-vecArray.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-benchmark-direct-vecArray fftw-benchmark-direct-vecArray.c

bin/fftw-benchmark-advance-vecArray: fftw-benchmark-advance-vecArray.c
	$(CC) $(C_COMPILE) $(C_INCLUDE) $(C_LINK) -o bin/fftw-benchmark-advance-vecArray fftw-benchmark-advance-vecArray.c

benchmarks/vector_transform_direct.txt: bin/fftw-benchmark-direct-vecArray
	bin/fftw-benchmark-direct-vecArray | tee benchmarks/vector_transform_direct.txt

benchmarks/vector_transform_advance.txt: bin/fftw-benchmark-advance-vecArray
	bin/fftw-benchmark-advance-vecArray | tee benchmarks/vector_transform_advance.txt

.PHONY: benchmark-direct-advance
benchmark-direct-advance: benchmarks/vector_transform_direct.txt bin/fftw-benchmark-advance-vecArray

.PHONY: plot-benchmark-direct-advance
plot-benchmark-direct-advance: benchmarks/vector_transform_direct.txt benchmarks/vector_transform_advance.txt
	@$(PYTHON) plot_benchmarks_direct-advance.py \
		benchmarks/vector_transform_direct.txt \
		benchmarks/vector_transform_advance.txt

