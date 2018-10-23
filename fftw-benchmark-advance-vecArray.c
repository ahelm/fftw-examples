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

double execute_plans(fftw_plan **plan, const int N)
{
  timing_t t;

  tick(&t);
  fftw_execute(**plan);
  tock(&t);
  return get_timing(&t);
}

void setup_simple_1d(double **in, fftw_complex **out, fftw_plan **plan, const int N, const int vec_dim)
{
  *in = fftw_malloc(sizeof(double) * N * vec_dim);
  *out = fftw_malloc(sizeof(fftw_complex) * (N / 2 + 1) * vec_dim);
  *plan = fftw_malloc(sizeof(fftw_plan));

  int n[] = {N};
  int idist = N;
  int odist = N / 2 + 1;

  int istride = 1;
  int ostride = 1;

  int inembed[] = {N};
  int onembed[] = {N / 2 + 1};

  **plan = fftw_plan_many_dft_r2c(
      1,
      n,
      vec_dim,
      *in,
      inembed,
      istride,
      idist,
      *out,
      onembed,
      ostride,
      odist,
      FFTW_ESTIMATE);
}

void cleanup_simple_1d(double **in, fftw_complex **out, fftw_plan **plan, const int vec_dim)
{
  fftw_destroy_plan(**plan);
  fftw_free(*plan);
  fftw_free(*in);
  fftw_free(*out);
}

void execute_benchmark(fftw_plan **plan, const int N, const int vec_dim, const int howmany_runs)
{
  double timing = 0.0;
  for (int n = 0; n < howmany_runs; n++)
  {
    timing += execute_plans(plan, vec_dim);
  }
  fprintf(stdout, "%u, %u, %u, %e\n", N, howmany_runs, vec_dim, timing);
  fflush(stdout);
}

int main(int argc, char const *argv[])
{
  int N_max = 4096;
  int howmany_runs = 1000;
  int vec_dim = 6;

  double *arr;
  fftw_complex *out;
  fftw_plan *plan;

  // prints header
  fprintf(stdout, "# N, how_many_runs, vec_dim, total_time[s]\n");

  for (int v = 1; v <= vec_dim; v++)
  {
    for (int N = 1; N <= N_max; N++)
    {
      setup_simple_1d(&arr, &out, &plan, N, v);
      execute_benchmark(&plan, N, v, howmany_runs);
      cleanup_simple_1d(&arr, &out, &plan, v);
    }
  }
}
