%% FM Receiver - TASK 5: Time-Frequency Analysis (STFT)
% Compares original audio, denoised audio, and the removed noise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

%% 1. Load Audio Data
disp('Loading audio files from Task 2 and Task 4...');
try
    [y_orig, fs] = audioread('Task2_InitialAudio.wav');
    [y_denoised, ~] = audioread('Task4_DenoisedAudio.wav');
catch
    error('Could not find the .wav files. Ensure Tasks 2 and 4 have been run.');
end

% Ensure vectors are the same length (truncate to the shortest)
min_len = min(length(y_orig), length(y_denoised));
y_orig = y_orig(1:min_len);
y_denoised = y_denoised(1:min_len);

% Calculate the exact noise that was removed by the filter
y_noise = y_orig - y_denoised;

%% 2. Deliverable 1: STFT Spectrograms
disp('Generating STFT Spectrograms...');
window = hamming(1024);
noverlap = 512;
nfft = 1024;

fig1 = figure('Name', 'Task 5: STFT Spectrograms', 'Position', [100, 100, 900, 800]);

% (a) Original Noisy Audio
subplot(3,1,1);
[S1, F1, T1] = spectrogram(y_orig, window, noverlap, nfft, fs, 'yaxis');
imagesc(T1, F1/1e3, 10*log10(abs(S1).^2 + eps));
axis xy; colormap(turbo); c = colorbar; c.Label.String = 'Power (dB)';
title('(a) STFT of Original Noisy Audio');
ylabel('Frequency (kHz)');
caxis([-80 0]); % Normalize color scaling across plots

% (b) Wiener Denoised Audio
subplot(3,1,2);
[S2, F2, T2] = spectrogram(y_denoised, window, noverlap, nfft, fs, 'yaxis');
imagesc(T2, F2/1e3, 10*log10(abs(S2).^2 + eps));
axis xy; colormap(turbo); c = colorbar; c.Label.String = 'Power (dB)';
title('(b) STFT of Wiener Denoised Audio');
ylabel('Frequency (kHz)');
caxis([-80 0]);

% (c) Filtered Noise (What was removed)
subplot(3,1,3);
[S3, F3, T3] = spectrogram(y_noise, window, noverlap, nfft, fs, 'yaxis');
imagesc(T3, F3/1e3, 10*log10(abs(S3).^2 + eps));
axis xy; colormap(turbo); c = colorbar; c.Label.String = 'Power (dB)';
title('(c) STFT of Filtered Noise (Removed from Signal)');
xlabel('Time (seconds)');
ylabel('Frequency (kHz)');
caxis([-80 0]);

% Auto-save Figure 1
exportgraphics(fig1, 'Task5_Spectrograms.png', 'Resolution', 300);

%% 3. Deliverable 2: Comparative Waveform Plots
disp('Generating Waveform Comparisons...');
% Zoom in on a tiny 0.05-second slice so the noise is visible to the naked eye
start_sample = fs * 2.0; % Start at 2.0 seconds
end_sample = start_sample + round(0.05 * fs); % 50 milliseconds long
t_axis = (0:(end_sample-start_sample-1)) / fs * 1000; % Time in ms

slice_orig = y_orig(start_sample:end_sample-1);
slice_denoised = y_denoised(start_sample:end_sample-1);

fig2 = figure('Name', 'Task 5: Waveform Comparison', 'Position', [150, 150, 900, 600]);

subplot(2,1,1);
plot(t_axis, slice_orig, 'b', 'LineWidth', 1);
title('Original Noisy Waveform (Time Domain)');
ylabel('Amplitude');
grid on; ylim([-1 1]);

subplot(2,1,2);
plot(t_axis, slice_denoised, 'r', 'LineWidth', 1);
title('Wiener Denoised Waveform (Time Domain)');
xlabel('Time (milliseconds)');
ylabel('Amplitude');
grid on; ylim([-1 1]);

% Auto-save Figure 2
exportgraphics(fig2, 'Task5_Waveforms.png', 'Resolution', 300);

disp('======================================================');
disp('Task 5 Complete. Final plots saved successfully!');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%