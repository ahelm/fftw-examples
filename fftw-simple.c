#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <math.h>

#include <fftw3.h>

#ifndef ARRAY_LENGTH
#define ARRAY_LENGTH 512
#endif

#define RE(a) a[0]
#define IM(a) a[1]
#define AS_DOUBLE(a) (double)(a)

#define NOISE_LEVEL 10.0 // noise level in percent
#define NOISE_MAX 100.0  // maximum noise level

// create a signal of a shape of sin^2 with just one bump
void create_signal(fftw_complex *arr, int N)
{
  int boundary = 4;

  for (int i = 0; i < N; i++)
  {
    if ((i < boundary) || (i > (N - boundary)))
    {
      RE(arr[i]) = 0.0;
      IM(arr[i]) = 0.0;
    }
    else
    {
      RE(arr[i]) = pow(sin(AS_DOUBLE(i - boundary) / AS_DOUBLE(N - 2 * boundary) * M_PI), 2);
      IM(arr[i]) = pow(sin(AS_DOUBLE(i - boundary) / AS_DOUBLE(N - 2 * boundary) * M_PI), 2);
    }
    // randomize data
    RE(arr[i]) += (float)rand() / (float)(RAND_MAX) * (NOISE_LEVEL / NOISE_MAX);
    IM(arr[i]) += (float)rand() / (float)(RAND_MAX) * (NOISE_LEVEL / NOISE_MAX);
  }
}

// printout value values
void print_arr(fftw_complex *arr, int N, FILE *stream)
{

  for (int i = 0; i < N; i++)
  {
    fprintf(stream, "%.8e\t%.8e\n", RE(arr[i]), IM(arr[i]));
  }
}

// dump raw data
void dump_raw(fftw_complex *arr, const int N, const char *file_name)
{
  FILE *fp = fopen(file_name, "wb");
  assert(fp);
  fwrite(arr, sizeof arr[0], N, fp);
  fclose(fp);
}

int main(int argc, char const *argv[])
{
  int N = ARRAY_LENGTH;
  fftw_complex *in, *out;
  fftw_plan p, p_inv;

  in = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);
  out = (fftw_complex *)fftw_malloc(sizeof(fftw_complex) * N);

  p = fftw_plan_dft_1d(N, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
  p_inv = fftw_plan_dft_1d(N, in, out, FFTW_BACKWARD, FFTW_ESTIMATE);

  create_signal(in, N);
  print_arr(in, N, stdout);

  fftw_execute(p);
  fftw_execute(p_inv);

  print_arr(in, N, stderr);

  // store raw data
  dump_raw(in, N, "fftw_simple_in.raw");
  dump_raw(out, N, "fftw_simple_out.raw");

  fftw_destroy_plan(p);
  fftw_destroy_plan(p_inv);
  fftw_free(in);
  fftw_free(out);

  return 0;
}
