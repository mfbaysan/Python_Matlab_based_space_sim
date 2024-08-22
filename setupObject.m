function setupObject(rcsObject, boundingBox)
plotObject = false;

maxRelativeObjectSpeed = 15e3;
nObjects = 1;                           % Number of objects
%r1 = 0.05;                              % Major semi-axis length of cylinder
%r2 = 0.05;                              % Minor semi-axis length of cylinder
%height = 0.02;                          % Height of the cylinder
%rcsSteps = 1e6;
%[rcspat,azout,elout] = rcscylinder(r1,r2,height,c,freq:rcsSteps:freq+pulseBw);

pathname = 'C:\Users\fatih\PycharmProjects\correlation_IDP\rcs_files' ;
cd(pathname)

rcspat = readmatrix(rcsObject);
azout = -180:180;
elout = -90:90;
fluctuationModel = 'Swerling1';         % Fluctuation model

for i = 1:nObjects
    object = struct;
    startingRotation = [rand*360 rand*360 rand*360];
    rotationPerPulse = rand(1,3)*0.1;   % pitch yaw roll
    
    bWr = tand(antBw/2)*maxRange;
    
    bWrSampleX = 2*bWr*(rand-0.5);
    while true
        bWrSampleZ = 2*bWr*(rand-0.5);
        if bWrSampleX^2 + bWrSampleZ^2 <= bWr^2
            break
        end
    end
    radarCoverageSample = [bWrSampleX, maxRange, bWrSampleZ]*rand;
    startingPositionPre = radarCoverageSample+randn(1,3);
    startingPositionVector = startingPositionPre - radarCoverageSample;
    startingPositionVector = startingPositionVector/norm(startingPositionVector);
    
    objectSpeed = rand*maxRelativeObjectSpeed;
    object.speed = objectSpeed;
    startingPosition = radarCoverageSample + startingPositionVector * pri * ...
                round(numPulses/2) * objectSpeed;
    
    objectVelocityVector = radarCoverageSample - startingPosition;
    objectVelocity = objectVelocityVector/norm(objectVelocityVector)*objectSpeed;
    object.velocity = objectVelocity;
    
    cylinderWaypoints = zeros(numPulses,3);
    cylinderRotations = repmat(quaternion([0 0 0],'eulerd','zyx','frame'), ...
        numPulses, 1);
    
    currentRotation = startingRotation;
    endPosition = pri * numPulses * objectVelocity + startingPosition;
    for tt = 1:numPulses % Loop over time
        cylinderWaypoints(tt,:) = endPosition*tt/numPulses + startingPosition*(numPulses - tt)/numPulses;
        cylinderRotations(tt) = quaternion(currentRotation,'eulerd','zyx','frame');
        currentRotation = currentRotation + rotationPerPulse;
    end
    object.waypoints = cylinderWaypoints;
    object.rotations = cylinderRotations;
    traj = waypointTrajectory('SampleRate',scene.UpdateRate, ...
                'TimeOfArrival',scene.SimulationTime:1/prf:scene.StopTime, ...
                'Waypoints',cylinderWaypoints, 'Orientation', cylinderRotations);
    rcspatdb = mag2db(rcspat);
    rcssig = rcsSignature('Pattern', rcspatdb, ...
            'Azimuth', azout, 'Elevation', elout, ...
            'Frequency', [freq, freq+pulseBw], 'FluctuationModel', fluctuationModel);
    object.rcssig = rcssig;
    cylinderplat = platform(scene,'Trajectory',traj,'Signatures',rcssig, ...
        'Dimensions', ...
        struct('Length',boundingBox.x,'Width',boundingBox.y,'Height',boundingBox.z,'OriginOffset',[0 0 0]));
end
end
