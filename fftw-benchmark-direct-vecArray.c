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

double execute_plans(fftw_plan **plans, const int N)
{
  timing_t t;

  tick(&t);
  for (int i = 0; i < N; i++)
  {
    fftw_plan *plan = *plans + i;
    fftw_execute(*plan);
  }
  tock(&t);
  return get_timing(&t);
}

void setup_simple_1d(double **in, fftw_complex **out, fftw_plan **plans, const int N, const int vec_dim)
{
  *in = fftw_malloc(sizeof(double) * N * vec_dim);
  *out = fftw_malloc(sizeof(fftw_complex) * (N / 2 + 1) * vec_dim);
  *plans = malloc(sizeof(fftw_plan) * vec_dim);

  for (int i = 0; i < vec_dim; i++)
  {
    fftw_plan *plan = *plans + i;
    *plan = fftw_plan_dft_r2c_1d(
        N,
        *in + i * N,
        *out + i * (N / 2 + 1),
        FFTW_ESTIMATE);
  }
}

void cleanup_simple_1d(double **in, fftw_complex **out, fftw_plan **plans, const int vec_dim)
{
  for (int i = 0; i < vec_dim; i++)
  {
    fftw_plan *plan = *plans + i;
    fftw_destroy_plan(*plan);
  }
  fftw_free(*plans);
  fftw_free(*in);
  fftw_free(*out);
}

void execute_benchmark(fftw_plan **plans, const int N, const int vec_dim, const int howmany_runs)
{
  double timing = 0.0;
  for (int n = 0; n < howmany_runs; n++)
  {
    timing += execute_plans(plans, vec_dim);
  }
  fprintf(stdout, "%u, %u, %u, %e\n", N, howmany_runs, vec_dim, timing);
  fflush(stdout);
}

int main(int argc, char const *argv[])
{
  int N_max = 4096;
  int howmany_runs = 100;
  int vec_dim = 6;

  double *arr;
  fftw_complex *out;
  fftw_plan *plans;

  // prints header
  fprintf(stdout, "# N, how_many_runs, vec_dim, total_time[s]\n");

  for (int v = 1; v <= vec_dim; v++)
  {
    for (int N = 1; N <= N_max; N++)
    {
      setup_simple_1d(&arr, &out, &plans, N, v);
      execute_benchmark(&plans, N, v, howmany_runs);
      cleanup_simple_1d(&arr, &out, &plans, v);
    }
  }
}
