import numpy as np
from matplotlib import pyplot as plt

d = 0.1
guards = 5

xmin = 0.0
xmax = 10.0
N = int((xmax - xmin) / d)

xmin_pad = xmin - guards * d
xmax_pad = xmax + guards * d
N_pad = N + 2 * guards

print(f"N = {N} / N_padded = {N_pad}")

xaxis = np.linspace(xmin, xmax, N)
xaxis_pad = np.linspace(xmin_pad, xmax_pad, N_pad)


def create_signal(x, center=5.0, width=10.0, mode="random"):
    if mode == "sin2":
        out = np.cos((x - center) / width * np.pi) ** 2.0
        out[x < (center - width / 2.0)] = 0.0
        out[x > (center + width / 2.0)] = 0.0
        return out
    if mode == "random":
        return np.random.random_sample(x.shape)

    raise ValueError("No valid mode selected!")


def pad_zeros(sig, p):
    return np.pad(sig, pad_width=(p, p), mode="constant")


# real space example
signal = create_signal(xaxis, mode="sin2")
signal_pad = pad_zeros(signal, guards)

plt.figure(figsize=(8, 6))
plt.subplot(2, 2, 1)
plt.title("Signal in real space")
plt.plot(xaxis, signal, "o", label="No padding")
plt.plot(xaxis_pad, signal_pad, "x", label=f"Padding = {guards}")
plt.legend()
plt.xlabel("$x$")
plt.ylabel("$f(x)$")

# calculate spectrum in k-space
kaxis = np.fft.rfftfreq(len(xaxis), d=d)
kaxis_pad = np.fft.rfftfreq(len(xaxis_pad), d=d)

fft_signal = np.fft.rfft(signal)
fft_signal_pad = np.fft.rfft(signal_pad)

plt.subplot(2, 2, 2)
plt.title("Signal in k-space (Abs)")
plt.plot(kaxis, np.abs(fft_signal), "-", label="No padding")
plt.plot(kaxis_pad, np.abs(fft_signal_pad), "-", label=f"Padding = {guards}")
plt.yscale("log")
plt.legend()
plt.xlabel("$k$")
plt.ylabel("$|\mathcal{FFT}[f]\,(k)|$")

plt.subplot(2, 2, 3)
plt.title("Signal in k-space (Real part)")
plt.plot(kaxis, np.real(fft_signal), "-", label="No padding")
plt.plot(kaxis_pad, np.real(fft_signal_pad), "-", label=f"Padding = {guards}")
plt.legend()
plt.xlabel("$k$")
plt.ylabel("$\mathcal{Re}(\mathcal{FFT}[f]\,(k))$")

plt.subplot(2, 2, 4)
plt.title("Signal in k-space (Imag part)")
plt.plot(kaxis, np.imag(fft_signal), "-", label="No padding")
plt.plot(kaxis_pad, np.imag(fft_signal_pad), "-", label=f"Padding = {guards}")
plt.legend()
plt.xlabel("$k$")
plt.ylabel("$\mathcal{Im}(\mathcal{FFT}[f]\,(k))$")

plt.tight_layout()
plt.show()
