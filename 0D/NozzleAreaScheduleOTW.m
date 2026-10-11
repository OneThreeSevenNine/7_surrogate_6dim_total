function [A8use,CD8use,A8effUse] = NozzleAreaScheduleOTW( ...
    nozzleCommand,A8Takeoff,CD8Takeoff,A8geomTOref,A8geomCRref, ...
    A8effTOref,A8effCRref)
%NOZZLEAREASCHEDULEOTW Schedule the OTW D-nozzle area for a steady point.
% nozzleCommand = 1: takeoff/open; 0: cruise/closed.
% Values between 0 and 1 are retained for transition and sensitivity work.
%
% A8Takeoff and CD8Takeoff are the calibrated 0D takeoff-point values.
% The report geometry/effective-area ratios are used to preserve that
% calibration while imposing the documented cruise-to-takeoff change.

if ~isscalar(nozzleCommand) || ~isfinite(nozzleCommand) || ...
        nozzleCommand < 0 || nozzleCommand > 1
    error('nozzleCommand must be a finite scalar in [0,1].');
end

if any(~isfinite([A8Takeoff,CD8Takeoff,A8geomTOref,A8geomCRref, ...
        A8effTOref,A8effCRref])) || ...
        any([A8Takeoff,CD8Takeoff,A8geomTOref,A8geomCRref, ...
        A8effTOref,A8effCRref] <= 0)
    error('All OTW nozzle areas and coefficients must be positive and finite.');
end

geomRatioCR = A8geomCRref/A8geomTOref;
effRatioCR = A8effCRref/A8effTOref;

% Linear interpolation is applied to geometric area and effective area
% independently. This makes CD vary consistently instead of treating the
% physical opening and the mass-flow capacity as the same quantity.
geomScale = geomRatioCR + nozzleCommand*(1-geomRatioCR);
effScale = effRatioCR + nozzleCommand*(1-effRatioCR);

A8use = A8Takeoff*geomScale;
A8effUse = A8Takeoff*CD8Takeoff*effScale;
CD8use = A8effUse/A8use;
end
