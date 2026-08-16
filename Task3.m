%% FM Receiver - TASK 3: Baseband Low-Pass Filtering & Architecture Comparison
% FIR (Linear Phase) vs IIR (Non-linear Phase)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
clear;
close all;

%% 1. Load Data from Task 2
disp('Loading raw I/Q data from Task 2...');
load('Task2_RawData.mat'); % loads: rxData, fs, fc, timestamp

% Use a manageable subset (0.2 sec)
subset_len = round(0.2 * fs);
rxData_sub = rxData(1:subset_len);

% Sanity checks
disp('--- Data sanity check ---');
disp(size(rxData_sub));
disp(['Has NaN: ', num2str(any(isnan(rxData_sub)))]);
disp(['Has Inf: ', num2str(any(isinf(rxData_sub)))]);
disp(['Max amplitude: ', num2str(max(abs(rxData_sub)))]);

%% 2. Filter Specifications
fc_filter = 100e3;        % 100 kHz cutoff
Wn = fc_filter / (fs/2);  % normalized cutoff

disp('Designing FIR and IIR filters...');

% FIR (linear phase)
N_fir = 100;
b_fir = fir1(N_fir, Wn, 'low');
a_fir = 1;

% IIR (Chebyshev Type II)
N_iir = 10;
[b_iir, a_iir] = cheby2(N_iir, 60, Wn);

%% 3. Apply Filters
disp('Applying filters...');
rxData_fir = filter(b_fir, a_fir, rxData_sub);
rxData_iir = filter(b_iir, a_iir, rxData_sub);

%% 4. Filter Response Plots
disp('Generating filter response plots...');
n_pts = 2048;

[H_fir, f_ax] = freqz(b_fir, a_fir, n_pts, fs);
[H_iir, ~]    = freqz(b_iir, a_iir, n_pts, fs);

[gd_fir, ~] = grpdelay(b_fir, a_fir, n_pts, fs);
[gd_iir, ~] = grpdelay(b_iir, a_iir, n_pts, fs);

fig1 = figure('Name', 'Task 3: Filter Responses', 'Position', [100, 100, 900, 700]);

% Magnitude
subplot(3,1,1);
plot(f_ax/1e3, 20*log10(abs(H_fir)+eps), 'b', 'LineWidth', 1.5); hold on;
plot(f_ax/1e3, 20*log10(abs(H_iir)+eps), 'r--', 'LineWidth', 1.5);
xline(fc_filter/1e3, 'k:', 'Cutoff (100 kHz)');
title('Magnitude Response');
ylabel('Magnitude (dB)');
legend('FIR (Order 100)', 'IIR (Chebyshev Type II Order 8)');
xlim([0 300]); ylim([-80 5]); grid on;

% Phase
subplot(3,1,2);
plot(f_ax/1e3, unwrap(angle(H_fir)), 'b', 'LineWidth', 1.5); hold on;
plot(f_ax/1e3, unwrap(angle(H_iir)), 'r--', 'LineWidth', 1.5);
title('Unwrapped Phase Response');
ylabel('Phase (rad)');
xlim([0 300]); grid on;

% Group delay
subplot(3,1,3);
plot(f_ax/1e3, gd_fir/fs*1e6, 'b', 'LineWidth', 1.5); hold on;
plot(f_ax/1e3, gd_iir/fs*1e6, 'r--', 'LineWidth', 1.5);
title('Group Delay');
xlabel('Frequency (kHz)');
ylabel('Delay (\mus)');
xlim([0 300]); ylim([0 50]); grid on;

exportgraphics(fig1, 'Task3_FilterResponses.png', 'Resolution', 300);

%% 5. Spectrograms (FIXED)
disp('Generating spectrograms...');

window   = hamming(1024);
noverlap = 512;
nfft     = 1024;

fig2 = figure('Name', 'Task 3: Spectrograms', 'Position', [150, 150, 900, 800]);

% --- (a) Unfiltered ---
subplot(3,1,1);
[S,F,T] = spectrogram(rxData_sub, window, noverlap, nfft, fs, 'centered');
imagesc(T*1e3, F, 20*log10(abs(S)+eps));
axis xy;
title('(a) Unfiltered Baseband Signal');
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
colormap(turbo);
colorbar;

% --- (b) FIR filtered ---
subplot(3,1,2);
[S,F,T] = spectrogram(rxData_fir, window, noverlap, nfft, fs, 'centered');
imagesc(T*1e3, F, 20*log10(abs(S)+eps));
axis xy;
title('(b) Isolated via FIR Low-Pass Filter');
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
colormap(turbo);
colorbar;

% --- (c) IIR filtered ---
subplot(3,1,3);
[S,F,T] = spectrogram(rxData_iir, window, noverlap, nfft, fs, 'centered');
imagesc(T*1e3, F, 20*log10(abs(S)+eps));
axis xy;
title('(c) Isolated via IIR Low-Pass Filter');
xlabel('Time (ms)');
ylabel('Frequency (Hz)');
colormap(turbo);
colorbar;

exportgraphics(fig2, 'Task3_Spectrograms.png', 'Resolution', 300);

disp('Done.');