function operatingPoint = IdentifyOperatingPointOTW(Altitude,Ma)
%IDENTIFYOPERATINGPOINTOTW Identify the standard OTW operating condition.
% Altitude is in metres. Unknown combinations return 'CUSTOM'.

if ~isscalar(Altitude) || ~isfinite(Altitude) || ...
        ~isscalar(Ma) || ~isfinite(Ma)
    error('Altitude and Ma must be finite scalars.');
end

altitudeTolerance = 1e-3; % m
machTolerance = 1e-6;

if isClose(Altitude,0,altitudeTolerance) && ...
        isClose(Ma,0,machTolerance)
    operatingPoint = 'TO';
elseif isClose(Altitude,60.96,altitudeTolerance) && ...
        isClose(Ma,0.121,machTolerance)
    operatingPoint = 'EOF';
elseif isClose(Altitude,7620,altitudeTolerance) && ...
        isClose(Ma,0.7,machTolerance)
    operatingPoint = 'CR';
else
    operatingPoint = 'CUSTOM';
end
end

function tf = isClose(value,target,tolerance)
tf = abs(value-target) <= tolerance;
end
