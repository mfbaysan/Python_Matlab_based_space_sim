%%% Run this script after running setup.m

%% Plots
plotIQ = false;
plotRangeDoppler = true;

%% Initialize output datacube
ib = 0; 
timeVec = 0:1/fs:(pri - 1/fs); 
rngVec = [0 time2range(timeVec(2:end))];
idx = find(rngVec > maxRange,1,'first'); 
numSamplesPulse = tpd*fs + 1;
numSamples = idx + numSamplesPulse - 1; 
iqsig = zeros(numSamples,nRx,numPulses);

%% Collect data
disp('Simulating IQ...')
restart(scene)
while advance(scene)
    % Collect IQ
    ib = ib + 1; 
    tmp = receive(scene);
    iqsig(:,:,ib) = tmp{1};

    % Update progress 
    if mod(ib,100) == 0
        fprintf('\t%.1f %% completed.\n',ib/numPulses*100); 
    end
end
%if plotIQ == true
%    hRaw = helperPlotRawIQ(squeeze(iqsig(:,1,:)));
%end

%% Generate Range-Doppler Response
% Only done using the first rx
% Beamforming has to be done to utilize all rx
rangedoppler = phased.RangeDopplerResponse(...
    'RangeMethod','FFT',...
    'PropagationSpeed',c,...
    'DopplerOutput','Speed',...
    'OperatingFrequency',freq,...
    'SampleRate', fs, ...
    'SweepSlope', pulseBw/tpd,...
    'PRFSource','Property', ...
    'PRF',prf, ...
    'ReferenceRangeCentered', false);
%if plotRangeDoppler == true
%    plotResponse(rangedoppler,squeeze(iqsig(:,1,:)))
%end
