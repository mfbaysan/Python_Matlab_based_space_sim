%% PARAMETERS THAT CAN BE CHANGED
% Parameters
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
noiseFigure = 15;                       % Receiver noise figure (dB)
objectDistanceFromRadar = 1000;         % Object distance from radar (m)
startingRotation = [0 0 0];             % Object starting rotation (pitch yaw roll)
rotationPerSecond = [0 0 0];            % Object rotation per second (pitch yaw roll)

objectPosition = [0, objectDistanceFromRadar, 0];

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
rdr.ReceiveAntenna.Sensor = ant;
rdr.ReceiveAntenna.OperatingFrequency = freq;
rdr.Receiver.SampleRate = fs;

% Estimate the antenna gain
antennaGain = beamwidth2gain(antBw,'ParabolicCircular'); 
rdr.Transmitter.Gain = antennaGain;
rdr.Receiver.Gain = antennaGain;
rdr.Receiver.NoiseFigure = noiseFigure;

% Configure the waveform
rdr.Waveform = phased.LinearFMWaveform('SampleRate',fs,'PulseWidth',tpd, ...
    'PRF',prf,'SweepBandwidth',pulseBw);

% Mount radar sensor on a stationary platform
time = 0:pri:(numPulses - 1)*pri;
rdrplatPos = [0 0 0];
rdrplat = platform(scene,'Position',rdrplatPos);
rdrplat.Sensors = rdr;

%% Object parameters and motion
maxRelativeObjectSpeed = 15e3;
nObjects = 1;                           % Number of objects
r1 = 0.1;                              % Major semi-axis length of cylinder
r2 = 0.1;                              % Minor semi-axis length of cylinder
height = 0.1;                          % Height of the cylinder
rcsSteps = 1e6;
[rcspat,azout,elout] = rcscylinder(r1,r2,height,c,freq:rcsSteps:freq+pulseBw);
fluctuationModel = 'Swerling1';         % Fluctuation model

rotationPerPulse = rotationPerSecond*pri;
objectRotations = repmat(quaternion([0 0 0],'eulerd','zyx','frame'), ...
    numPulses, 1);

objectWaypoints = zeros(numPulses,3);
currentRotation = startingRotation;
for tt = 1:numPulses % Loop over time
    objectWaypoints(tt,:) = objectPosition;
    objectRotations(tt) = quaternion(currentRotation,'eulerd','zyx','frame');
    currentRotation = currentRotation + rotationPerPulse;
end
traj = waypointTrajectory('SampleRate',scene.UpdateRate, ...
            'TimeOfArrival',scene.SimulationTime:1/prf:scene.StopTime, ...
            'Waypoints', objectWaypoints, 'Orientation', objectRotations);
rcspatdb = mag2db(rcspat);
rcssig = rcsSignature('Pattern', rcspatdb, ...
        'Azimuth', azout, 'Elevation', elout, ...
        'Frequency', freq:rcsSteps:freq+pulseBw, 'FluctuationModel', fluctuationModel);
objectplat = platform(scene,'Trajectory',traj,'Signatures',rcssig);

%plotScene(rdrplatPos,antBw,maxRange,objectWaypoints);

%% Initialize output datacube
ib = 0; 
timeVec = 0:1/fs:(pri - 1/fs); 
rngVec = [0 time2range(timeVec(2:end))];
idx = find(rngVec > maxRange,1,'first'); 
numSamplesPulse = tpd*fs + 1;
numSamples = idx + numSamplesPulse - 1; 
iqsig = zeros(numSamples,numPulses);

%% Collect data
disp('Simulating IQ...')
restart(scene)
while advance(scene)
    % Collect IQ
    ib = ib + 1; 
    tmp = receive(scene);
    iqsig(:,ib) = tmp{1};

    % Update progress 
    if mod(ib,100) == 0
        fprintf('\t%.1f %% completed.\n',ib/numPulses*100); 
    end
end
% hRaw = helperPlotRawIQ(iqsig);
