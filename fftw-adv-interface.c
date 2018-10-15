#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include <fftw3.h>

#define AS_DOUBLE(a) (double)(a)
#define RE(a) a[0]
#define IM(a) a[1]

#define NOISE_LEVEL 50.0

void create_signal(double *arr, const int vec_N, const int N, const int bnd)
{
  for (int i = 0; i < N; i++)
  {
    float x = (float)rand() / (float)(RAND_MAX) / NOISE_LEVEL;
    if ((i / vec_N) < bnd || (i / vec_N + 1) > (N / vec_N - bnd))
    {
      arr[i] = 0.5 + x;
    }
    else
    {
      arr[i] = pow(sin(AS_DOUBLE(i - bnd) / AS_DOUBLE(N - 2 * bnd) * M_PI), 2) + x;
    }
  }
}

void store_array(double *arr, const int vec_N, const int N, char *file_name)
{
  FILE *fp = fopen(file_name, "w");
  if (!fp)
  {
    perror("File opening failed");
    exit(EXIT_FAILURE);
  }

  for (int i = 0; i < N; i++)
  {
    for (int f = 0; f < vec_N; f++)
    {
      fprintf(fp, "  %e", arr[(i * vec_N) + f]);
    }
    fprintf(fp, "\n");
  }
  fclose(fp);
}

void normalize(double *arr, const int N, const double fact)
{

  for (int i = 0; i < N; i++)
  {
    arr[i] /= fact;
  }
}

int main(void)
{
  // definition for the 3d vector in 1d with guard points
  int field_dim = 3; // dimension of vector field
  int N = 512;       // length of vector field

  int len_1d = N;
  int total_length = field_dim * len_1d;
  double *arr = fftw_malloc(total_length * sizeof(double));
  fftw_complex *out = fftw_malloc(sizeof(fftw_complex) * (total_length / 2 + 1) * field_dim);

  create_signal(arr, field_dim, total_length, 0);
  store_array(arr, field_dim, len_1d, "adv_pre.txt");

  // plan for advanced interface
  int rank = 1;
  int n[] = {N};
  int howmany = field_dim;

  int idist = 1;
  int odist = 1;

  int istride = field_dim;
  int ostride = field_dim;

  int inembed[] = {N};
  int onembed[] = {N / 2 + 1};

  fftw_plan p, p_inv;

  // TODO: It will be wrong if we don't use `FFTW_ESTIMATE`
  p = fftw_plan_many_dft_r2c(
      rank,
      n,
      howmany,
      arr,
      inembed,
      istride,
      idist,
      out,
      onembed,
      ostride,
      odist,
      FFTW_ESTIMATE);

  // TODO: It will be wrong if we don't use `FFTW_ESTIMATE`
  p_inv = fftw_plan_many_dft_c2r(
      rank,
      n,
      howmany,
      out,
      onembed,
      ostride,
      odist,
      arr,
      inembed,
      istride,
      idist,
      FFTW_ESTIMATE);

  fftw_execute(p);
  fftw_execute(p_inv);

  normalize(arr, total_length, (double)N);

  store_array(arr, field_dim, len_1d, "adv_post.txt");

  fftw_destroy_plan(p);
  fftw_destroy_plan(p_inv);
  fftw_free(arr);
  fftw_free(out);
}