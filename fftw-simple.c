#include <stdio.h>
#include <math.h>

#include <fftw3.h>

#define RE(a) a[0]
#define IM(a) a[1]
#define AS_DOUBLE(a) (double)(a)

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

int main(int argc, char const *argv[])
{
  int N = 512;
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

  fftw_destroy_plan(p);
  fftw_destroy_plan(p_inv);
  fftw_free(in);
  fftw_free(out);

  return 0;
}
