%% FM File Receiver
% Here in this program we use RTL_SDR to receive data frame length wise and
% annyalze the spectrum for each frame to find the presence of desired
% frequencies
function FM_Read_Record_For_Scanner(rtlsdr_fc,sim_time,filename)
%% PARAMETERS
% Here we Define the input parameters for the RTL_SDR to receive the data
% of certain frequency

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rtlsdr_id        = '0';                              % stick ID
rtlsdr_gain      = 49.6;                                                             % tuner gain in dB
rtlsdr_fs        =  250e3;                                                           % tuner sampling rate
rtlsdr_ppm       = -2;                                                                 % tuner parts per million correction
rtlsdr_frmlen    =600*625;                                                      % output data frame size (must be a multiple of 5)
rtlsdr_datatype  = 'single';                                                      % output data type
audio_fs         = 48e3;                                                            % audio output sampling rate


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% FRAME CALCULATIONS
% Here we define the center frequency after removing the offset frequency
% of the RTL_SDR for accurate data reception and calculate the  framelength
% for data processing


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


rtlsdr_fc = rtlsdr_fc-40e3;                                                       % add 40kHz offset to tuner frequency entered by user
rtlsdr_frmtime = rtlsdr_frmlen/rtlsdr_fs;                                  % calculate time for 1 frame of data


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% SYSTEM OBJECTS
% Here in this section we define the object that uses the tool box function
% of RTL_SDR to receive data as per the parameters that are defined in the
% parameters section and then we also define the object FM Demodulator function of
% communication tool box to demodulate the signal received from the
% RTL_SDR.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Llink to a physical rtl-sdr
obj_rtlsdr = comm.SDRRTLReceiver(...
    rtlsdr_id,...
    'CenterFrequency', rtlsdr_fc,...
    'EnableTunerAGC', false,...
    'TunerGain', rtlsdr_gain,...
    'SampleRate', rtlsdr_fs, ...
    'SamplesPerFrame', rtlsdr_frmlen,...
    'OutputDataType', rtlsdr_datatype,...
    'FrequencyCorrection', rtlsdr_ppm);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Creating a FM broadcast receiver object
fmBroadcastDemod = comm.FMBroadcastDemodulator(...
    'SampleRate',  rtlsdr_fs, ...
    'FrequencyDeviation', 75e3, ...
    'FilterTimeConstant', 7.5000e-5, ...
    'AudioSampleRate', audio_fs, ...
    'Stereo', false,'PlaySound',true);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% SIMULATION
% Here we simulate the receiver by calling the objects from the object
% function attached with the relevant input to perform the intended
% operations to give out the desired result

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% if using RTL-SDR, check first if RTL-SDR is active

if ~isempty(sdrinfo(obj_rtlsdr.RadioAddress))
else
    error(['RTL-SDR failure. Please check connection to ',...
        'MATLAB using the "sdrinfo" command.']);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% reset run_time to 0 (secs)
run_time = 0;

% loop while run_time is less than sim_time
while run_time < sim_time
    %% Fetch a frame from obj_rtlsdr

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    [ rtlsdr_data,len,lost,late] = step(obj_rtlsdr);
    if norm(rtlsdr_data)>100
        audioSig = fmBroadcastDemod(rtlsdr_data);


 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Computing the Spectrum for the RTL-SDR data

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        % Computing FFT for the frame data
        n = 1024;
        rtlsdr_rdata_fft  = abs(fftshift(fft(rtlsdr_data,1024)));

        % Plotting the FFT data
        L = length(rtlsdr_data);
        t = (-n/2:n/2-1)/n*rtlsdr_fs;
        figure(1);subplot(2,1,1);plot(t,rtlsdr_rdata_fft);
        title("FFT Spectrum Analysis of Received FM Audio Signal")
        xlabel("Frequency");ylabel("Number of Samples");

        %Plotting pspectrum for the FFT data
        Pxx=rtlsdr_rdata_fft.*conj(rtlsdr_rdata_fft)/(L*L); %computing power with proper scaling
        subplot(2,1,2);plot(t,10*log10(Pxx),'r');
        title('Power Spectral Density - RTL-SDR Data');
        xlabel('Frequency (Hz)')
        ylabel('Power Spectral Density- P_{xx} dB/Hz');

        %plotting spectrogram (waterfall diagram) for the fft data
        figure(2);subplot(2,1,1);pspectrum(rtlsdr_rdata_fft,audio_fs,'spectrogram','OverlapPercent',0,'Leakage',1,'MinThreshold',-60,'TimeResolution', 10e-3);

        % Plotting of Histogram Values
        subplot(2,1,2);histogram(real(rtlsdr_data)); title('Histogram - RTL-SDR Data');

        %% Computing the Spectrum for the Demodulated data
        % Computing FFT for the frame data
        rtlsdr_data_fft  = abs(fftshift(fft(audioSig,1024)));

        % Plotting the FFT data
        L = length(audioSig);
        t = (-n/2:n/2-1)/n*rtlsdr_fs;
        figure(3);subplot(2,1,1);plot(t,rtlsdr_data_fft);
        title("FFT Spectrum Analysis of Demodulated FM Audio Signal")
        xlabel("Frequency");ylabel("Number of Samples");

        %Plotting pspectrum for the FFT data
        Pxx=rtlsdr_data_fft.*conj(rtlsdr_data_fft)/(L*L); %computing power with proper scaling
        subplot(2,1,2);plot(t,10*log10(Pxx),'r');
        title('Power Spectral Density - Demodulated Data');
        xlabel('Frequency (Hz)')
        ylabel('Power Spectral Density- P_{xx} dB/Hz');

        %plotting spectrogram (waterfall diagram) for the fft data
        figure(4);subplot(2,1,1);pspectrum(rtlsdr_data_fft,audio_fs,'spectrogram','OverlapPercent',0,'Leakage',1,'MinThreshold',-60,'TimeResolution', 10e-3);

        % Plotting of Histogram Values
        subplot(2,1,2);histogram(audioSig); title('Histogram - Demodulated Data');

        

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Creating a empty binary file to write the data

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        %Creating a binary data file in write mode to append the values
        fid =  fopen(filename,'a');
        fwrite(fid,audioSig,'double');
        fclose('all');


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        run_time = run_time + rtlsdr_frmtime;
        disp("The samples lost during reception: "+lost);
        disp("The latency of reception: "+late);


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
end
disp('Data Reception Completed Succesfully');
pause(2);
%% Reopening the file to read the data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


id = fopen(filename,"r");
data = fread(id,'double');
soundsc(data,audio_fs);
fclose(id);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
