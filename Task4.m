%% FM Receiver - TASK 4: Optimal Denoising via Wiener Filtering
% Enhances audio quality by subtracting estimated noise floor P_nn(f)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

%% 1. Load Audio Data
disp('Loading initial audio from Task 2...');
try
    [y, fs] = audioread('Task2_InitialAudio.wav');
    y = y(:); % Ensure column vector
catch
    error('Could not find Task2_InitialAudio.wav. Make sure it is in the current folder.');
end

%% 2. Short-Time Fourier Transform (STFT)
% We process the audio in small overlapping chunks to analyze frequencies over time
win_len = 1024;
overlap = 512;
nfft = 1024;
win = hamming(win_len);

disp('Performing STFT...');
[S, f_stft, t_stft] = stft(y, fs, 'Window', win, 'OverlapLength', overlap, 'FFTLength', nfft);

%% 3. Estimate Noise Power Spectrum P_nn(f)
disp('Estimating Noise Power Spectrum...');
% Calculate power of each STFT frame
P_yy = abs(S).^2;
frame_energy = sum(P_yy, 1);

% Find the "silent intervals" by isolating the quietest 10% of audio frames
[~, sorted_idx] = sort(frame_energy);
num_noise_frames = max(1, round(0.1 * length(sorted_idx)));
noise_idx = sorted_idx(1:num_noise_frames);

% Average the power spectrum across those quiet frames to get our noise profile
P_nn = mean(P_yy(:, noise_idx), 2);

%% 4. Apply Wiener Filter Transfer Function
disp('Applying Wiener Filter...');
% Estimate pure signal power: P_ss(f) = P_yy(f) - P_nn(f) 
% (Threshold at 0 to avoid negative power)
P_ss = max(P_yy - P_nn, 0);

% Calculate Transfer Function: H(f) = P_ss / (P_ss + P_nn)
% Adding small epsilon (eps) to denominator to prevent division by zero
H = P_ss ./ (P_ss + P_nn + eps);

% Apply filter to the complex STFT matrix
S_denoised = H .* S;

%% 5. Reconstruct Audio
disp('Reconstructing audio via Inverse STFT...');
y_denoised = istft(S_denoised, fs, 'Window', win, 'OverlapLength', overlap, 'FFTLength', nfft);

% Match lengths just in case of block-padding
if length(y_denoised) > length(y)
    y_denoised = y_denoised(1:length(y));
else
    y = y(1:length(y_denoised));
end

% Normalize audio to prevent speaker clipping
y_denoised = y_denoised / max(abs(y_denoised));

% Save audio file
audiowrite('Task4_DenoisedAudio.wav', y_denoised, fs);
disp('Denoised audio saved as Task4_DenoisedAudio.wav');

%% 6. Power Spectrum Comparison Plot
disp('Generating Power Spectrum comparison...');
% Calculate Global PSD using Welch's method for a clean, smoothed plot
[pxx_orig, f_psd] = pwelch(y, win, overlap, nfft, fs);
[pxx_denoised, ~] = pwelch(y_denoised, win, overlap, nfft, fs);

fig4 = figure('Name', 'Task 4: Wiener Filter', 'Position', [200, 200, 800, 500]);
plot(f_psd/1e3, 10*log10(pxx_orig), 'b', 'LineWidth', 1.2); hold on;
plot(f_psd/1e3, 10*log10(pxx_denoised), 'r', 'LineWidth', 1.2);
title('Power Spectrum: Original vs. Wiener Denoised Audio');
xlabel('Frequency (kHz)');
ylabel('Power/Frequency (dB/Hz)');
legend('Original Noisy Signal', 'Wiener Denoised Signal');
grid on;
xlim([0 fs/2000]); % Show up to Nyquist frequency (24 kHz)

% Auto-save Figure
exportgraphics(fig4, 'Task4_PowerSpectrum.png', 'Resolution', 300);
disp('Plot automatically saved as Task4_PowerSpectrum.png');
disp('======================================================');
disp('Task 4 Complete. Listen to both .wav files to hear the difference!');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%