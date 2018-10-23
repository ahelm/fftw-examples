# run first FFTW_simple - to store the data
import numpy as np
import matplotlib.pyplot as plt


in_arr = np.fromfile("fftw_simple_in.raw", dtype=np.double)
in_arr = np.reshape(in_arr, (512, 2))
np_in = in_arr[:, 0] + 1.0j * in_arr[:, 1]

plt.figure()
plt.title("input arr")
plt.plot(in_arr[:, 0], "o", mfc="none")
plt.plot(in_arr[:, 1], "o", mfc="none")
plt.plot(np.real(np_in), "x")
plt.plot(np.imag(np_in), "x")


out_arr = np.fromfile("fftw_simple_out.raw", dtype=np.double)
out_arr = np.reshape(out_arr, (512, 2))
np_out = np.fft.fft(np_in)

plt.figure()
plt.title("|output arr - numpy output|")
plt.plot(out_arr[:, 0], "o", mfc="none")
plt.plot(out_arr[:, 1], "o", mfc="none")
plt.plot(np.real(np_out), "x")
plt.plot(np.imag(np_out), "x")

plt.show()
