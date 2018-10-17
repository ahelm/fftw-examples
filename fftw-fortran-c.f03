!
! HELPER -----------------------------------------------------------------------
module helper

implicit none

real(kind=8), parameter :: PI = 3.14159265358979323846264338327950288
real(kind=8), parameter :: NOISE_LEVEL = 10.0   ! in percent
real(kind=8), parameter :: NOISE_MAX = 100.0

contains

subroutine create_signal(arr, n, fdim, pad)
  implicit none
  real(kind=8), dimension(:, :), pointer :: arr
  integer, intent(in) :: n, fdim, pad
  integer :: i, j
  real :: harvest

  do i = 1, n
    arr(:, i) = sin(real(i - 1, kind=8) / real(n, kind=8) * PI) ** 2.0
  enddo

  do i = 1 - pad, 1
    arr(:, i) = 0.5
  enddo

  do i = n, n + pad
    arr(:, i) = 0.5
  enddo

  ! randomize the data - does not need to be fully random
  call random_seed()
  do j = lbound(arr, dim=2), ubound(arr, dim=2)
    do i = lbound(arr, dim=1), ubound(arr, dim=1)
      call random_number(harvest)
      arr(i, j) = arr(i, j) + (NOISE_LEVEL/NOISE_MAX) * harvest
    enddo
  enddo
end subroutine create_signal

subroutine create_linear_signal(arr, n, fdim, pad)
  implicit none
  real(kind=8), dimension(:, :), pointer :: arr
  integer, intent(in) :: n, fdim, pad
  integer :: i, f

  do i = lbound(arr, dim=2), ubound(arr, dim=2)
    do f = lbound(arr, dim=1), ubound(arr, dim=1)
      arr(f, i) = i + (f - 1)
    enddo
  enddo

end subroutine create_linear_signal

subroutine store_arr(arr, file_name)
  implicit none
  real(kind=8), dimension(:, :), pointer :: arr
  character(len=*), intent(in) :: file_name
  integer :: i, fdim, ios
  character(len=512) :: fmt
  character(len=10)  :: fdim_c
  integer, parameter :: fid = 123

  open(unit=fid, file=trim(file_name), iostat=ios, action="write")
  if ( ios /= 0 ) then
    print *, "Error opening file: " // trim(file_name)
    stop
  endif

  fdim = size(arr, dim=1)
  write(fdim_c, "(I10)") fdim
  fmt = "(" //  trim(fdim_c) // "E20.5)"

  do i = lbound(arr, dim=2), ubound(arr, dim=2)
    write(fid, trim(fmt)) arr(:, i)
  enddo

  close(unit=fid, iostat=ios)
  if ( ios /= 0 ) then
    print *, "Error closing file: " // trim(file_name)
  endif
end subroutine store_arr

subroutine normalize(arr, N)

  implicit none

  real(kind=8), dimension(:, :), pointer :: arr
  integer, intent(in) :: N

  integer :: i, f

  do i = 1, N
    do f = lbound(arr, dim=1), ubound(arr, dim=1)
      arr(f, i) = arr(f, i) / real(N)
    enddo
  enddo

end subroutine normalize

end module helper
! ------------------------------------------------------------------------------
!
! FFTW3 ------------------------------------------------------------------------
module FFTW3
use, intrinsic :: iso_c_binding
include "fftw3.f03"
end module FFTW3
! ------------------------------------------------------------------------------
!
! FFT UTILS --------------------------------------------------------------------
module fft_utils

use FFTW3

implicit none

  type :: fft_handler
    integer :: in_len
    integer :: out_len
    integer :: fdim

    type(c_ptr) :: plan_forward
    type(c_ptr) :: plan_backward

    real(kind=8), dimension(:,:), pointer :: in_arr
    complex(c_double_complex), dimension(:,:), pointer :: out_arr

  contains

    procedure :: setup => setup_fft
    procedure :: cleanup => cleanup_fft
    procedure :: forward => fft
    procedure :: backward => ifft

  end type fft_handler

contains

subroutine setup_fft(this, arr, fdim, n)

  implicit none

  class(fft_handler), intent(inout) :: this
  real(kind=8), dimension(:, :), intent(inout), pointer :: arr
  integer, intent(in) :: fdim, n

  integer, dimension(2) :: shape_arr
  integer :: out_ub, ierr

  ! auxiliary parameters for plan planning
  integer :: rank, howmany
  integer, dimension(1) :: plan_length

  integer :: istride, idist, ostride, odist
  integer, dimension(1) :: inembed, onembed

  ! store transform specific parameters
  this%in_len = n
  this%fdim = fdim

  ! create k-space field array
  this%out_len = this%in_len / 2 + 1
  allocate(this%out_arr(1:this%fdim, 1:this%out_len), stat=ierr)
  if (ierr /= 0) then
    print *, "Allocation failed for this%out_arr"
    stop
  endif

  ! link outter array to
  this%in_arr(1:, 1:) => arr(1:fdim, 1:n)

  !!! parameters for planning
  ! general
  rank = 1
  plan_length = (/ this%in_len /)
  howmany = this%fdim
  ! input parameters
  inembed = (/ this%in_len /)
  istride = this%fdim
  idist = 1
  ! output parameters
  onembed = (/ this%out_len /)
  ostride = this%fdim
  odist = 1

  ! create plans
  this%plan_forward = fftw_plan_many_dft_r2c( &
      rank, plan_length, howmany, &
      this%in_arr, inembed, istride, idist, &
      this%out_arr, onembed, ostride, odist, &
      FFTW_PATIENT &
    )

  this%plan_backward = fftw_plan_many_dft_c2r( &
      rank, plan_length, howmany, &
      this%out_arr, onembed, ostride, odist, &
      this%in_arr, inembed, istride, idist, &
      FFTW_PATIENT &
    )
end subroutine setup_fft

subroutine cleanup_fft(this)

  implicit none

  class(fft_handler), intent(inout) :: this
  integer :: ierr

  call fftw_destroy_plan(this%plan_forward)
  call fftw_destroy_plan(this%plan_backward)

  deallocate(this%out_arr, stat=ierr)
  if (ierr /= 0) then
    print *, "Deallocation failed for this%out_arr"
    stop
  endif

  nullify(this%in_arr)

end subroutine cleanup_fft

subroutine fft(this)
  implicit none
  class(fft_handler), intent(inout) :: this

  call fftw_execute_dft_r2c(this%plan_forward, this%in_arr, this%out_arr)
end subroutine fft

subroutine ifft(this)
  implicit none
  class(fft_handler), intent(inout) :: this

  call fftw_execute_dft_c2r(this%plan_backward, this%out_arr, this%in_arr)
end subroutine ifft

end module fft_utils
! ------------------------------------------------------------------------------
!
! ARRAY HELPERS ----------------------------------------------------------------
module array_helpers

implicit none

contains

subroutine setup(arr, fdim, n, pad)
  implicit none
  real(kind=8), pointer, intent(inout) :: arr(:,:)
  integer, intent(in) :: fdim, n, pad
  integer :: ierr, lb, ub

  lb = 1 - pad
  ub = n + pad

  allocate(arr(1:fdim, lb:ub), stat=ierr)
  if (ierr /= 0) then
    print *, "Allocation failed"
    stop
  endif

end subroutine setup

subroutine cleanup(arr)
  implicit none
  real(kind=8), pointer, intent(inout) :: arr(:,:)
  integer :: ierr

  deallocate(arr, stat=ierr)
  if (ierr /= 0) then
    print *, "Deallocation failed"
    stop
  endif

end subroutine cleanup

end module array_helpers
! ------------------------------------------------------------------------------
!
! MAIN -------------------------------------------------------------------------
program fftw_fortran_c

  use helper
  use fft_utils
  use array_helpers

  implicit none

  integer, parameter :: N = 512
  integer, parameter :: fdim = 2
  integer, parameter :: pad = 25

  integer :: err
  integer :: left_bound, right_bound

  real(kind=8), dimension(:,:), pointer :: field_data
  type(fft_handler) :: fft_hndl

  call setup(field_data, fdim, N, pad)
  call fft_hndl%setup(field_data, fdim, N)

  call create_signal(field_data, N, fdim, pad)
  call store_arr(field_data, "fortran_pre.txt")

  call fft_hndl%forward()
  call fft_hndl%backward()

  call normalize(field_data, N)
  call store_arr(field_data, "fortran_post.txt")

  call fft_hndl%cleanup()
  call cleanup(field_data)

end program fftw_fortran_c
! ------------------------------------------------------------------------------