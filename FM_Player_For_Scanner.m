%% Software FM Receiver using RTL_SDR for FM/VHF/UHF Signals
% This software works on the basis of receiving data through a RTL_SDR
% which is then processed using FM Demodulator from Communication Tool Box
% and are processed framelength wise to play the real time broadcast of
% that particular frequency for required time length.


function FM_Player_For_Scanner(rtlsdr_fc,sim_time)
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
                          % simulation time in seconds


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

    % fetch a frame from obj_rtlsdr (live or offline)
    rtlsdr_data = step(obj_rtlsdr);
    rtlsdr_data=rtlsdr_data-mean(rtlsdr_data);


    if norm(rtlsdr_data)>100
        audioSig = fmBroadcastDemod(rtlsdr_data);


        run_time = run_time + rtlsdr_frmtime;
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%