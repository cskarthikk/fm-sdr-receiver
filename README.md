# 📡 FM Software-Defined Radio — DSP Lab

A complete **software-defined FM radio receiver** built in MATLAB, using an RTL-SDR dongle. The project covers the full signal-processing pipeline — from raw RF scanning and I/Q capture, through filtering and demodulation, to audio denoising and time-frequency analysis.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Hardware & Software Requirements](#hardware--software-requirements)
- [Project Structure](#project-structure)
- [Pipeline](#pipeline)
- [Tasks](#tasks)
  - [Task 1 — Band Scanning & Station Detection](#task-1--band-scanning--station-detection)
  - [Task 2 — Data Acquisition & Baseline Demodulation](#task-2--data-acquisition--baseline-demodulation)
  - [Task 3 — Baseband Filtering: FIR vs IIR](#task-3--baseband-filtering-fir-vs-iir)
  - [Task 4 — Wiener Filter Denoising](#task-4--wiener-filter-denoising)
  - [Task 5 — Time-Frequency Analysis (STFT)](#task-5--time-frequency-analysis-stft)
- [Helper Functions](#helper-functions)
- [Outputs](#outputs)
- [How to Run](#how-to-run)
- [Key DSP Concepts Covered](#key-dsp-concepts-covered)
- [Authors](#authors)

---

## Overview

This project implements a fully functional **FM broadcast receiver** using software-defined radio (SDR) principles. A low-cost RTL-SDR USB dongle acts as the RF front-end, capturing raw **I/Q (in-phase/quadrature)** baseband samples. MATLAB then handles all signal processing: spectrum scanning, FM demodulation, digital filtering, noise suppression, and audio reconstruction.

---

## Hardware & Software Requirements

| Requirement | Details |
|---|---|
| **Hardware** | RTL-SDR USB dongle (RTL2832U chipset) |
| **MATLAB** | R2020b or later recommended |
| **Toolboxes** | Communications Toolbox, DSP System Toolbox, Signal Processing Toolbox |
| **MATLAB Support Package** | RTL-SDR Radio Support Package (`comm.SDRRTLReceiver`) |

> **Note:** Tasks 3, 4, and 5 can be run **without the RTL-SDR hardware** — they operate entirely on the `.mat` and `.wav` files saved in Tasks 1 and 2.

---

## Project Structure

```
.
├── Task1.m                      # FM band scanner & top station detector
├── Task2.m                      # Raw I/Q capture & baseline FM demodulation
├── Task3.m                      # FIR vs IIR low-pass filter comparison
├── Task4.m                      # Wiener filter audio denoising
├── Task5.m                      # STFT time-frequency analysis
│
├── FM_Player_For_Scanner.m      # Helper: real-time FM audio playback
├── FM_Read_Record_For_Scanner.m # Helper: FM reception + recording to file
│
├── raw_data.mat                 # Raw I/Q data (from scanner recording)
├── Task2_RawData.mat            # Raw I/Q data saved by Task 2
├── Task2_InitialAudio.wav       # Baseline demodulated audio
├── Task4_DenoisedAudio.wav      # Wiener-filtered output audio
│
├── Task1_PowerSpectrum.png      # Scanned band spectrum plot
├── Task2_TimeDomain.png         # Raw I/Q magnitude (time domain)
├── Task3_FilterResponses.png    # FIR vs IIR magnitude/phase/group delay
├── Task3_Spectrograms.png       # Spectrograms: unfiltered, FIR, IIR
├── Task4_PowerSpectrum.png      # PSD: original vs Wiener denoised
├── Task5_Spectrograms.png       # STFT: original, denoised, removed noise
└── Task5_Waveforms.png          # Waveform zoom: original vs denoised
```

---

## Pipeline

```
RTL-SDR (RF Front-End)
        │
        ▼
   Task 1: Band Scan
   (Sweep 88–108 MHz, identify FM stations via FFT peak detection)
        │
        ▼
   Task 2: I/Q Capture & Baseline FM Demodulation
   (Tune to target, capture raw I/Q, phase discriminator → audio)
        │
        ▼
   Task 3: Baseband Low-Pass Filtering
   (FIR Order-100  vs  IIR Chebyshev Type-II Order-10, 100 kHz cutoff)
        │
        ▼
   Task 4: Wiener Filter Denoising
   (STFT domain noise estimation from silent frames → H(f) filter)
        │
        ▼
   Task 5: Time-Frequency Analysis
   (STFT spectrograms — original / denoised / removed noise)
        │
        ▼
   Final Output: Denoised FM Audio (.wav)
```

---

## Tasks

### Task 1 — Band Scanning & Station Detection

**File:** `Task1.m`

Sweeps a user-specified frequency range (e.g., 88–108 MHz FM band) using overlapping RTL-SDR capture windows, builds a composite power spectrum via FFT, and identifies the **top 5 strongest FM stations** using `findpeaks`.

**Key steps:**
- Overlapping tuner sweeps at `fs = 2.8 MHz` with 50% overlap
- Per-frequency FFT with max-hold averaging over multiple frames
- `findpeaks` with 200 kHz minimum peak separation (standard FM channel spacing)
- 3 dB bandwidth estimation for each detected station
- Generates a labeled power spectrum plot and auto-saves as `Task1_PowerSpectrum.png`
- Offers real-time playback (`FM_Player_For_Scanner`) or record-to-file (`FM_Read_Record_For_Scanner`) of the assigned station

**Output:** `Task1_PowerSpectrum.png`

---

### Task 2 — Data Acquisition & Baseline Demodulation

**File:** `Task2.m`

Captures **5 seconds of raw I/Q data** at the target station frequency and performs a baseline FM demodulation without any advanced filtering.

**Key steps:**
- Tunes RTL-SDR to the target frequency at `fs = 2.4 MHz`
- Captures data in 0.1-second frames to avoid memory overload
- **FM Discriminator demodulation:**
  1. Pre-filter with a 100 kHz FIR LPF
  2. `unwrap(angle(...))` to extract instantaneous phase
  3. `diff(phase)` to obtain instantaneous frequency (= audio signal)
  4. `decimate` down to 48 kHz audio
- Saves raw I/Q data (`Task2_RawData.mat`) and demodulated audio (`Task2_InitialAudio.wav`)
- Plots and saves raw I/Q magnitude in the time domain

**Output:** `Task2_RawData.mat`, `Task2_InitialAudio.wav`, `Task2_TimeDomain.png`

---

### Task 3 — Baseband Filtering: FIR vs IIR

**File:** `Task3.m`  
**Requires:** `Task2_RawData.mat`

Compares two low-pass filter architectures for isolating the FM baseband signal (±100 kHz), studying the trade-offs in magnitude response, phase linearity, and group delay.

| Property | FIR (Order 100) | IIR (Chebyshev Type-II, Order 10) |
|---|---|---|
| Design method | `fir1` (windowed) | `cheby2` (60 dB stopband attenuation) |
| Phase response | **Linear** | Non-linear |
| Group delay | **Constant** | Varies with frequency |
| Computational cost | Higher | Lower |

**Plots generated:**
1. Magnitude response (dB)
2. Unwrapped phase response (rad)
3. Group delay (μs)
4. Spectrograms of: unfiltered / FIR-filtered / IIR-filtered baseband

**Output:** `Task3_FilterResponses.png`, `Task3_Spectrograms.png`

---

### Task 4 — Wiener Filter Denoising

**File:** `Task4.m`  
**Requires:** `Task2_InitialAudio.wav`

Applies an **STFT-domain Wiener filter** to remove broadband noise from the baseline demodulated audio.

**Algorithm:**
1. **STFT** of the noisy audio (Hamming window, 50% overlap, 1024-pt FFT)
2. **Noise PSD estimation** — average power spectrum of the quietest 10% of frames (minimum statistics approach)
3. **Wiener transfer function:**

```
H(f) = P_ss(f) / ( P_ss(f) + P_nn(f) )

where P_ss = max( P_yy - P_nn, 0 )  (estimated clean signal power)
      P_nn = noise power spectral density
```

4. Apply `H(f)` to the complex STFT, reconstruct via **ISTFT**
5. Compares PSD of original vs. denoised audio using Welch's method

**Output:** `Task4_DenoisedAudio.wav`, `Task4_PowerSpectrum.png`

---

### Task 5 — Time-Frequency Analysis (STFT)

**File:** `Task5.m`  
**Requires:** `Task2_InitialAudio.wav`, `Task4_DenoisedAudio.wav`

Final visual analysis comparing the original, denoised, and removed-noise signals in both the **time-frequency** (spectrogram) and **time** domains.

**Deliverables:**
1. **3-panel STFT spectrogram** (turbo colormap, consistent −80 to 0 dB color scale):
   - (a) Original noisy audio
   - (b) Wiener denoised audio
   - (c) Filtered noise (= original − denoised)
2. **Waveform zoom** — 50 ms slice at t = 2.0 s showing the noise reduction effect

**Output:** `Task5_Spectrograms.png`, `Task5_Waveforms.png`

---

## Helper Functions

### `FM_Player_For_Scanner(fc, sim_time)`

Real-time FM audio playback. Tunes RTL-SDR to `fc` Hz (with a −40 kHz DC offset correction), demodulates using `comm.FMBroadcastDemodulator`, and plays audio for `sim_time` seconds. Frames with insufficient signal power (`norm < 100`) are discarded to skip quiet/null bursts.

### `FM_Read_Record_For_Scanner(fc, sim_time, filename)`

Extends the player with **live spectrum visualization** — FFT, PSD, spectrogram, and histogram for both the raw RF and demodulated signals — and appends audio samples to a binary file frame-by-frame. After reception completes, reads the file back and plays via `soundsc`.

---

## Outputs

| File | Description |
|---|---|
| `Task1_PowerSpectrum.png` | Scanned FM band — power spectrum with top-station labels |
| `Task2_TimeDomain.png` | Raw I/Q signal magnitude vs. time |
| `Task2_InitialAudio.wav` | Baseline FM-demodulated audio (noisy) |
| `Task3_FilterResponses.png` | FIR vs IIR: magnitude, phase, group delay |
| `Task3_Spectrograms.png` | Baseband spectrograms — unfiltered, FIR, IIR |
| `Task4_DenoisedAudio.wav` | Wiener-filtered, denoised audio |
| `Task4_PowerSpectrum.png` | PSD comparison: original vs. denoised |
| `Task5_Spectrograms.png` | STFT spectrograms: original / denoised / noise |
| `Task5_Waveforms.png` | Time-domain waveform comparison (50 ms zoom) |

---

## How to Run

> Run tasks **in order** — each task depends on outputs from the previous one.

```matlab
% Step 1: Scan the FM band and tune to a station
% (Requires RTL-SDR hardware)
run('Task1.m')

% Step 2: Capture raw I/Q data and generate baseline audio
% (Requires RTL-SDR hardware)
run('Task2.m')

% Step 3: Compare FIR and IIR filter architectures
% (No hardware needed — uses Task2_RawData.mat)
run('Task3.m')

% Step 4: Apply Wiener denoising
% (No hardware needed — uses Task2_InitialAudio.wav)
run('Task4.m')

% Step 5: Time-frequency analysis
% (No hardware needed — uses Task2 and Task4 .wav files)
run('Task5.m')
```

---

## Key DSP Concepts Covered

- **Software-Defined Radio (SDR)** — RF-to-baseband I/Q sampling
- **FFT-based Spectrum Analysis** — Power spectrum estimation, peak detection
- **FM Demodulation** — Phase discriminator (instantaneous frequency extraction)
- **FIR vs IIR Filter Design** — Trade-offs in linearity, order, and computational cost
- **Short-Time Fourier Transform (STFT)** — Time-frequency signal representation
- **Wiener Filtering** — Optimal linear denoising in the spectral domain
- **Welch's PSD Estimation** — Averaged periodogram for smooth spectral analysis
- **Decimation** — Multi-rate signal processing for sample rate conversion

---

## Authors

- **Surya Karthik**
- **G V N Mokshagna**
