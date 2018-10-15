module helper

implicit none

real(kind=8), parameter :: PI = 3.14159265358979323846264338327950288

contains

subroutine create_signal(arr, n, fdim)
  implicit none
  real(kind=8), dimension(:, :), pointer :: arr
  integer, intent(in) :: n, fdim
  integer :: i, j
  real :: harvest

  do i = 1, n
    arr(:, i) = sin(real(i - 1, kind=8) / real(n, kind=8) * PI) ** 2.0
  enddo

  do i = lbound(arr, dim=2), 0
    arr(:, i) = 0.5
  enddo

  do i = n+1, ubound(arr, dim=2)
    arr(:, i) = 0.5
  enddo

  ! randomize the data - does not need to be fully random
  call random_seed()
  do j = lbound(arr, dim=2), ubound(arr, dim=2)
    do i = lbound(arr, dim=1), ubound(arr, dim=1)
      call random_number(harvest)
      arr(i, j) = arr(i, j) + 0.01 * harvest
    enddo
  enddo
end subroutine create_signal

subroutine store_arr(arr, file_name)
  implicit none
  real(kind=8), dimension(:, :), intent(in) :: arr
  character(len=*), intent(in) :: file_name
  integer :: i, ios
  integer, parameter :: fid = 123

  open(unit=fid, file=trim(file_name), iostat=ios, action="write")
  if ( ios /= 0 ) then
    print *, "Error opening file: " // trim(file_name)
    stop
  endif

  do i = lbound(arr, dim=2), ubound(arr, dim=2)
    write(fid,'(3E20.5)') arr(:, i)
  enddo

  close(unit=fid, iostat=ios)
  if ( ios /= 0 ) then
    print *, "Error closing file: " // trim(file_name)
  endif
end subroutine store_arr

end module helper

module FFTW3
use, intrinsic :: iso_c_binding
include "fftw3.f03"
end module FFTW3

module fft_utils

use FFTW3

implicit none

type :: fft_handler
  type(c_ptr) :: plan_forward
  type(c_ptr) :: plan_backward
end type fft_handler

contains
subroutine setup_fft(arr, fdim, n, fft_hndl)

  implicit none

  real(kind=8), dimension(:, :), intent(inout) :: arr
  integer, intent(in) :: fdim, n
  type(fft_handler), intent(inout) :: fft_hndl

  integer, dimension(2) :: shape_arr
  integer :: out_dim, ierr

  ! create k-space field array
  out_dim = n / 2 + 1
  allocate(fft_hndl%out_arr(1:fdim, 1:out_dim), stat=ierr)
  if (ierr /= 0) then
    print *, "Allocation failed for fft_hndl%out_arr"
    stop
  endif
end subroutine setup_fft

subroutine cleanup_fft(fft_hndl)

  implicit none

  type(fft_handler), intent(inout) :: fft_hndl
  integer :: ierr

  call fftw_destroy_plan(fft_hndl%plan_forward)
  call fftw_destroy_plan(fft_hndl%plan_backward)

  deallocate(fft_hndl%out_arr, stat=ierr)
  if (ierr /= 0) then
    print *, "Deallocation failed for fft_hndl%out_arr"
    stop
  endif

end subroutine cleanup_fft

subroutine fft(fft_hndl)
  implicit none
  type(fft_handler), intent(inout) :: fft_hndl
end subroutine fft

subroutine ifft(fft_hndl)
  implicit none
  type(fft_handler), intent(inout) :: fft_hndl
end subroutine ifft

end module fft_utils

module array_helpers

implicit none

contains

subroutine setup(arr, fdim, n, bnd)
  implicit none
  real(kind=8), pointer, intent(inout) :: arr(:,:)
  integer, intent(in) :: fdim, n, bnd
  integer :: ierr, lb, ub
  lb = 1 - bnd
  ub = n + bnd
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

program fftw_fortran_c

  use helper
  use fft_utils
  use array_helpers


  implicit none

  integer, parameter :: N = 512
  integer, parameter :: boundaries = 4
  integer, parameter :: fdim = 3

  integer :: err
  integer :: left_bound, right_bound

  real(kind=8), dimension(:,:), pointer :: field_data
  type(fft_handler) :: fft_hndl

  call setup(field_data, fdim, N, boundaries)
  call setup_fft(field_data, fdim, N, fft_hndl)

  call create_signal(field_data, N, fdim)
  call store_arr(field_data, "signal_pre.txt")

  call fft(fft_hndl)
  call ifft(fft_hndl)

  call cleanup_fft(fft_hndl)
  call cleanup(field_data)

end program fftw_fortran_c