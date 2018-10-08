CC=gcc-8
INCLUDE=-I $(shell brew --prefix fftw)/include
LINK=-L $(shell brew --prefix fftw)/lib -l fftw3 -l m

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