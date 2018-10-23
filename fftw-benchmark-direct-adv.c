#include <stdlib.h>
#include <time.h>
#include <math.h>
#include <fftw3.h>
#include <unistd.h>

// ------------------------------------------------------------------------------------
// Simple timing routines
// ------------------------------------------------------------------------------------
typedef struct
{
  clock_t start;
  clock_t end;
} timing_t;

void tick(timing_t *t_data)
{
  t_data->start = clock();
}

void tock(timing_t *t_data)
{
  t_data->end = clock();
}

double get_timing(timing_t *t_data)
{
  return ((double)(t_data->end - t_data->start)) / CLOCKS_PER_SEC;
}
// ------------------------------------------------------------------------------------
// ------------------------------------------------------------------------------------

double execute_plans(fftw_plan *plans, const int N)
{
  timing_t t;

  tick(&t);
  for (int i = 0; i < N; i++)
  {
    fftw_execute(plans[i]);
  }
  tock(&t);
  return get_timing(&t);
}

int get_in_offset(const int N)
{
  return N;
}

int get_out_offset(const int N)
{
  return N / 2 + 1;
}

void setup_simple_1d(double *in, fftw_complex *out, fftw_plan *plans, const int N, const int vec_dim)
{
  in = fftw_malloc(sizeof(double) * N * vec_dim);
  out = fftw_malloc(sizeof(fftw_complex) * (N / 2 + 1) * vec_dim);
  plans = malloc(sizeof(fftw_plan) * vec_dim);

  for (int i = 0; i < vec_dim; i++)
  {
    plans[i] = fftw_plan_dft_r2c_1d(
        N,
        in + i * get_in_offset(N),
        out + i * get_out_offset(N),
        FFTW_ESTIMATE_PATIENT);
  }
}

void cleanup_simple_1d(double *in, fftw_complex *out, fftw_plan *plans, const int vec_dim)
{
  for (int i = 0; i < vec_dim; i++)
  {
    fftw_destroy_plan(plans[i]);
  }
  fftw_free(plans);
  fftw_free(in);
  fftw_free(out);
}

int main(int argc, char const *argv[])
{
  // tiny benchmark to see time difference between regular interface and advanced
  int N = 1025;
  int howmany_runs = 1000;
  int vec_dim = 3;

  double *arr;
  fftw_complex *out;
  fftw_plan *plans;

  setup_simple_1d(arr, out, plans, N, vec_dim);

  double timing = 0.0;
  for (int n = 0; n < howmany_runs; n++)
  {
    timing += execute_plans(plans, vec_dim);
  }
  printf("execution time (%u loops)= %e s\n", howmany_runs, timing);

  cleanup_simple_1d(arr, out, plans, vec_dim);
}
