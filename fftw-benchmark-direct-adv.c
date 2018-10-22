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

int main(int argc, char const *argv[])
{
  // tiny benchmark to see time difference between regular interface and advanced
  int N = (int)pow(2, 100);
  int vec_dim = 1;

  double *arr = fftw_malloc(sizeof(double) * N * vec_dim);
  int arr_offset = N;
  fftw_complex *out = fftw_malloc(sizeof(fftw_complex) * (N / 2 + 1) * vec_dim);
  int out_offset = (N / 2 + 1);

  fftw_plan *plans = malloc(sizeof(fftw_plan) * vec_dim);

  for (int i = 0; i < vec_dim; i++)
  {
    plans[i] = fftw_plan_dft_r2c_1d(N, arr + i * arr_offset, out + i * out_offset, FFTW_ESTIMATE);
  }

  double timing = execute_plans(plans, vec_dim);
  printf("execution time = %g s\n", timing);

  for (int i = 0; i < vec_dim; i++)
  {
    fftw_destroy_plan(plans[i]);
  }
  fftw_free(plans);
  fftw_free(arr);
  fftw_free(out);
}
