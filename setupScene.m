%%% Run this script before simulation.m
% This is the a script to set uo the necessary variables in the workspace
% to simulate a radar scenario. This simulation is made for a pulse radar
% with linear frequency modulation. The parameters can be changed to create
% different target and radar scenarios.

%% PARAMETERS THAT CAN BE CHANGED
% Radar Parameters
c           = physconst('LightSpeed');  % DO NOT CHANGE THIS LINE
freq        = 94e9;                     % Frequency of the radar
lambda      = freq2wavelen(freq,c);     % DO NOT CHANGE THIS LINE
numPulses   = 100;                      % Number of pulses
prf         = 1/(80e-6);                % Pulse Repetition Frequency (Hz)
antBw       = 0.25;                     % Antenna beamwidth (deg)
pulseBw     = 50e6;                     % Bandwidth (Hz)
fs          = 2.1*pulseBw;              % Sampling frequency (Hz)
tpd         = 25e-6;                    % Pulse width (sec)
maxRange    = 8e3;                      % Maximum range (m)
minNoiseFigure = 15;       %  check     % Minimum radar receiver noise figure (dB)
maxNoiseFigure = 30;       %  check     % Maximum receiver noise figure (dB)
nRx = 1;                                % Number of receivers

%% Calculate range resolution (m)
rangeRes = bw2rangeres(pulseBw);

%% Create a radar scenario
pri = 1/prf;
simulationDuration = pri*(numPulses - 1);
scene = radarScenario('UpdateRate',prf,'StopTime',simulationDuration);

%% Create a radar transceiver
ant = phased.SincAntennaElement('Beamwidth',antBw);
rdr = radarTransceiver('MountingAngles',[90 0 0],'RangeLimits',[0 maxRange]); 
rdr.TransmitAntenna.Sensor = ant;
rdr.TransmitAntenna.OperatingFrequency = freq;
if nRx >= 2
    rdr.ReceiveAntenna.Sensor = phased.ULA('Element',ant, 'NumElements', nRx);
else
    rdr.ReceiveAntenna.Sensor = ant;
end
rdr.ReceiveAntenna.OperatingFrequency = freq;
rdr.Receiver.SampleRate = fs;

% Estimate the antenna gain
antennaGain = beamwidth2gain(antBw,'ParabolicCircular'); 
rdr.Transmitter.Gain = antennaGain;
rdr.Receiver.Gain = antennaGain;
noiseFigure = (maxNoiseFigure - minNoiseFigure)*rand + minNoiseFigure;
rdr.Receiver.NoiseFigure = noiseFigure;

% Configure the waveform
rdr.Waveform = phased.LinearFMWaveform('SampleRate',fs,'PulseWidth',tpd, ...
    'PRF',prf,'SweepBandwidth',pulseBw);

% Mount radar sensor on a stationary platform
time = 0:pri:(numPulses - 1)*pri;
rdrplatPos = [0 0 0];
rdrplat = platform(scene,'Position',rdrplatPos);
rdrplat.Sensors = rdr;
