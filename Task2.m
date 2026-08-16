%% FM Receiver - TASK 2: Data Acquisition and Raw Demodulation (CORRECTED)

clear;
close all;

%% 1. Parameters
fc = 98.41e6;           % Target Center Frequency from Task 1
fs = 2.4e6;             % Sample rate (2.4 MHz divides perfectly to 48kHz audio)
audio_fs = 48000;       % Standard audio sampling rate
decimation_factor = fs / audio_fs; % Decimation factor = 50
capture_duration = 5;   % Capture 5 seconds of data

% Frame parameters to prevent memory overload
frmLen = fs / 10;       % 240,000 samples per frame (0.1 seconds)
numFrames = capture_duration * 10; % 50 frames total for 5 seconds

%% 2. System Object Setup
disp(['Tuning RTL-SDR to ', num2str(fc/1e6), ' MHz...']);
try
    obj_rtlsdr = comm.SDRRTLReceiver(...
        '0', ...
        'CenterFrequency', fc, ...
        'EnableTunerAGC', true, ...
        'SampleRate', fs, ...
        'SamplesPerFrame', frmLen, ... % Safe frame size
        'OutputDataType', 'single');
catch
    error('RTL-SDR connection failed. Please check the hardware.');
end

%% 3. Data Acquisition
disp(['Capturing ', num2str(capture_duration), ' seconds of raw I/Q data in chunks...']);
timestamp = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
disp(['Timestamp: ', char(timestamp)]);

% Pre-allocate memory for speed
rxData = zeros(fs * capture_duration, 1);

% Loop to capture frames
for i = 1:numFrames
    rxData( (i-1)*frmLen + 1 : i*frmLen ) = step(obj_rtlsdr);
end

release(obj_rtlsdr);
disp('Data acquisition complete.');

%% 4. Save Raw Data
% Save the raw I/Q samples and timestamp to a .mat file
save_filename = 'Task2_RawData.mat';
save(save_filename, 'rxData', 'timestamp', 'fc', 'fs');
disp(['Raw data saved to ', save_filename]);

%% 5. Baseline FM Demodulation
disp('Performing baseline FM demodulation...');
% a) Limit bandwidth to FM broadcast limits (~200kHz) before demodulation
% using a simple lowpass filter to remove adjacent noise
b_lpf = fir1(100, 100e3/(fs/2)); 
rxData_filt = filter(b_lpf, 1, rxData);

% b) FM Discriminator: Extract phase and differentiate
% The derivative of phase represents the instantaneous frequency (the audio)
phase_data = unwrap(angle(rxData_filt));
demod_signal = diff(phase_data);

% c) Decimate to Audio Sample Rate (48 kHz)
% decimate function applies a lowpass anti-aliasing filter automatically
audio_signal = decimate(demod_signal, decimation_factor);

% Normalize audio for .wav file (-1 to 1 range)
audio_signal = audio_signal / max(abs(audio_signal));

%% 6. Save Audio File
audio_filename = 'Task2_InitialAudio.wav';
audiowrite(audio_filename, audio_signal, audio_fs);
disp(['Demodulated audio saved to ', audio_filename]);

%% 7. Time-Domain Plot of Raw I/Q Magnitude
% Plotting only a small subset (e.g., first 10,000 samples) so the plot is readable
num_samples_to_plot = 10000;
t_axis = (0:num_samples_to_plot-1) / fs;

fig = figure('Name', 'Task 2: Raw I/Q Signal Magnitude');
fig.Position = [100, 100, 800, 400];
plot(t_axis * 1e3, abs(rxData(1:num_samples_to_plot)), 'b');
title(['Raw I/Q Signal Magnitude (Time Domain) - $f_c$ = ', num2str(fc/1e6), ' MHz'], 'Interpreter', 'latex');
xlabel('Time (milliseconds)');
ylabel('Magnitude $|I + jQ|$', 'Interpreter', 'latex');
grid on;

% Auto-save the plot
exportgraphics(fig, 'Task2_TimeDomain.png', 'Resolution', 300);
disp('Plot automatically saved as Task2_TimeDomain.png');

disp('======================================================');
disp('Task 2 Complete. You can now play the .wav file.');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%