%% FM Band Scanner and Player - TASK 1
% This program scans for a particular frequency band, identifies the top 5 
% stations, calculates the assigned station based on roll number, labels the
% peaks, and tunes to the assigned frequency.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Parameters
disp("For searching of Stations............");
start_freq          = input("Enter the Start Frequency in MHz (e.g., 88).........")*1e6;         
stop_freq           = input("Enter the Stop Frequency in MHz (e.g., 108).........")*1e6;       
rtlsdr_id           = '0';          % RTL-SDR stick ID
rtlsdr_fs           = 2.8e6;        % RTL-SDR sampling rate in Hz
rtlsdr_gain         = 40;           % RTL-SDR tuner gain in dB
rtlsdr_frmlen       = 4096;         % RTL-SDR output data frame size
rtlsdr_datatype     = 'single';     % RTL-SDR output data type
rtlsdr_ppm          = -2;           % RTL-SDR tuner parts per million correction
disp('  ');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nfrmhold            = 20;           % number of frames to receive
fft_hold            = 'max';        % hold function "max" or "avg"
nfft                = 4096;         % number of points in FFTs (2^something)
dec_factor          = 16;           % output plot downsample
overlap             = 0.5;          % FFT overlap to counter rolloff
nfrmdump            = 100;          % number of frames to dump after retuning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of Tuning Frequencies
rtlsdr_tunerfreq  = start_freq:rtlsdr_fs*overlap:stop_freq;     
if( max(rtlsdr_tunerfreq) < stop_freq )                         
    rtlsdr_tunerfreq(length(rtlsdr_tunerfreq)+1) = max(rtlsdr_tunerfreq)+rtlsdr_fs*overlap;
end
nretunes = length(rtlsdr_tunerfreq);                            
freq_bin_width = (rtlsdr_fs/nfft);                              
freq_axis = (rtlsdr_tunerfreq(1)-rtlsdr_fs/2*overlap  :  freq_bin_width*dec_factor  :  (rtlsdr_tunerfreq(end)+rtlsdr_fs/2*overlap)-freq_bin_width)/1e6;

rtlsdr_data_fft = zeros(1,nfft);                     
fft_reorder = zeros(length(nfrmhold),nfft*overlap);  
fft_dec = zeros(nretunes,nfft*overlap/dec_factor);   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% System Object Function Determination
obj_rtlsdr = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency',      rtlsdr_tunerfreq(1),...
    'EnableTunerAGC', 		false,...
    'TunerGain', 			rtlsdr_gain,...
    'SampleRate',           rtlsdr_fs, ...
    'SamplesPerFrame', 		rtlsdr_frmlen,...
    'OutputDataType', 		rtlsdr_datatype ,...
    'FrequencyCorrection', 	rtlsdr_ppm );

obj_decmtr = dsp.FIRDecimator(...
    'DecimationFactor',     dec_factor,...
    'Numerator',            fir1(300,1/dec_factor));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Pre-Check and Simulation
if ~isempty(sdrinfo(obj_rtlsdr.RadioAddress))
else
    error('RTL-SDR failure. Please check connection to MATLAB using the "sdrinfo" command.');
end

for ntune = 1:1:nretunes
    obj_rtlsdr.CenterFrequency = rtlsdr_tunerfreq(ntune);
    disp("Scanning fc: " + rtlsdr_tunerfreq(ntune)/1e6 + " MHz.." );
    
    for frm = 1:1:nfrmdump
        rtlsdr_data = step(obj_rtlsdr);
    end
    
    for frm = 1:1:nfrmhold
        rtlsdr_data = step(obj_rtlsdr);
        rtlsdr_data = rtlsdr_data - mean(rtlsdr_data);
        rtlsdr_data_fft = abs(fft(rtlsdr_data,nfft))';
        fft_reorder(frm,( 1 : (overlap*nfft/2) ))      = rtlsdr_data_fft( (overlap*nfft/2)+(nfft/2)+1 : end );   
        fft_reorder(frm,( (overlap*nfft/2)+1 : end ))  = rtlsdr_data_fft( 1 : (overlap*nfft/2) );                
    end
    
    fft_reorder_proc = max(fft_reorder);
    fft_dec(ntune,:) = step(obj_decmtr,fft_reorder_proc')';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Data Manipulation and Representation
fft_masterreshape = reshape(fft_dec',1,ntune*nfft*overlap/dec_factor);

y_data = fft_masterreshape;
y_data_dbm = 10*log10((fft_masterreshape.^2)/50);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% TASK 1: Band Scanning, Peak Detection, and Roll Number Logic

% Calculate bin spacing in MHz
df = freq_axis(2) - freq_axis(1); 
% FM stations are typically separated by 200 kHz (0.2 MHz)
min_dist_bins = round(0.2 / df); 

% Find peaks in the spectrum
[pks, locs] = findpeaks(y_data_dbm, 'SortStr', 'descend', 'MinPeakDistance', min_dist_bins);

% Extract Top 5
num_peaks_to_find = min(5, length(pks));
top_5_pwr = pks(1:num_peaks_to_find);
top_5_idx = locs(1:num_peaks_to_find);
top_5_freq = freq_axis(top_5_idx);

% Calculate 3dB Bandwidth for the deliverables table
bw_est = zeros(1, num_peaks_to_find);
for i = 1:num_peaks_to_find
    p = top_5_pwr(i);
    idx = top_5_idx(i);
    
    % Find left 3dB point
    left_idx = idx;
    while left_idx > 1 && y_data_dbm(left_idx) > p - 3
        left_idx = left_idx - 1;
    end
    % Find right 3dB point
    right_idx = idx;
    while right_idx < length(y_data_dbm) && y_data_dbm(right_idx) > p - 3
        right_idx = right_idx + 1;
    end
    % Bandwidth in kHz
    bw_est(i) = (freq_axis(right_idx) - freq_axis(left_idx)) * 1000; 
end

% -------------------------------------------------------------------------
%% 
% Roll Number Calculation
roll_num = 2024230; 
assigned_index = mod(roll_num, 5) + 1;

disp(' ');
disp('======================================================');
disp(['Roll Number: BT', num2str(roll_num)]);
disp(['Assigned Station Index: (', num2str(roll_num), ' mod 5) + 1 = ', num2str(assigned_index)]);
disp('======================================================');

disp('--- Top 5 Stations (PSD) ---');
disp('Rank | Frequency (MHz) | Power (dBm) | Est. 3dB Bandwidth (kHz)');
for i = 1:num_peaks_to_find
    fprintf('  %d  |    %8.3f     |  %7.2f    |       ~%.1f \n', i, top_5_freq(i), top_5_pwr(i), bw_est(i));
end
disp('======================================================');

% Assigning Target Frequency based on Roll Number
target_freq = top_5_freq(assigned_index);
rtlsdr_fc = round(target_freq, 2) * 1e6;

disp(['==> Tuning to Assigned Target Frequency (Rank ', num2str(assigned_index), '): ', num2str(rtlsdr_fc/1e6), ' MHz']);
disp(' ');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Plotting with Top 5 Labels & Auto-Save
fig = figure(1);
fig.Position = [100, 100, 800, 600]; % Resize for better report fitting

subplot(2,1,1);
plot(freq_axis, y_data_dbm);
hold on;
% Plot red triangles on the top 5 peaks
plot(top_5_freq, top_5_pwr, 'rv', 'MarkerFaceColor', 'r'); 
% Add rank text labels above the peaks
for i = 1:num_peaks_to_find
    text(top_5_freq(i), top_5_pwr(i) + 3, num2str(i), 'Color', 'red', 'FontSize', 10, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
hold off;
title(sprintf('Spectrum of Band of Signal (Target: Rank %d, %.2f MHz)', assigned_index, target_freq));
xlabel(" Frequency (MHz) "); ylabel(" Power Ratio (dBm) ");

subplot(2,1,2);
plot(freq_axis, y_data);
xlabel(" Frequency (MHz) "); ylabel("Relative Power (Watts)");

% --- AUTO SAVE PLOT ---
exportgraphics(fig, 'Task1_PowerSpectrum.png', 'Resolution', 300);
disp('Plot automatically saved as Task1_PowerSpectrum.png');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Actions
disp("Choose the following actions to be performed: ......");
disp("1. Read and Play of Audio Signal");
disp("2. Read, Play and Record of Audio Signal");
disp("  ");
choice = input("Enter 1 or 2 to perform the desired actions.........");

if choice==1
    sim_time = input("Enter the run time: ");
    release(obj_rtlsdr);
    
    disp("Tuning the Receiver to " + rtlsdr_fc/1e6 + " MHz for data reception.............");
    disp("  ");
    FM_Player_For_Scanner(rtlsdr_fc,sim_time);
    
elseif choice==2
    sim_time = input("Enter the run time........");
    filename = input("Enter file name to store the recorded data (e.g., 'raw_data.mat').....", 's');
    release(obj_rtlsdr);
    
    disp("Tuning the Receiver to " + rtlsdr_fc/1e6 + " MHz for data reception.............");
    disp("  ");
    FM_Read_Record_For_Scanner(rtlsdr_fc,sim_time,filename);
else
    disp("Inappropriate choice");
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%