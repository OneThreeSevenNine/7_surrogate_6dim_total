function [nozzleCommand,flightPhase,operatingPoint] = ...
    ResolveNozzleCommandOTW(Altitude,Ma,flightPhase,nozzleCommandOverride)
%RESOLVENOZZLECOMMANDOTW Resolve the steady OTW D-nozzle opening command.
% Priority: numeric override, explicit flight phase, standard condition.
% nozzleCommand is 1 for takeoff/open and 0 for cruise/closed.

if nargin < 3 || isempty(flightPhase)
    flightPhase = '';
end
if nargin < 4
    nozzleCommandOverride = [];
end

operatingPoint = IdentifyOperatingPointOTW(Altitude,Ma);

if ~isempty(nozzleCommandOverride)
    validateCommand(nozzleCommandOverride);
    nozzleCommand = nozzleCommandOverride;
    if isempty(flightPhase)
        flightPhase = 'override';
    else
        flightPhase = canonicalPhase(flightPhase);
    end
    return;
end

if ~isempty(flightPhase)
    flightPhase = canonicalPhase(flightPhase);
    switch flightPhase
        case {'takeoff','eof','approach'}
            nozzleCommand = 1;
        case {'climb','cruise'}
            nozzleCommand = 0;
        case 'custom'
            error(['flight_phase=''custom'' requires ', ...
                'nozzle_command_override in [0,1].']);
        otherwise
            error('Unsupported flight phase: %s.',flightPhase);
    end
    return;
end

switch operatingPoint
    case {'TO','EOF'}
        nozzleCommand = 1;
        flightPhase = 'takeoff';
    case 'CR'
        nozzleCommand = 0;
        flightPhase = 'cruise';
    otherwise
        error(['The operating condition H=%.6g m, Ma=%.6g is not a ', ...
            'standard OTW point. Set flight_phase or ', ...
            'nozzle_command_override explicitly.'],Altitude,Ma);
end
end

function phase = canonicalPhase(value)
if isstring(value)
    if ~isscalar(value)
        error('flight_phase must be a character vector or string scalar.');
    end
    value = char(value);
elseif ~ischar(value)
    error('flight_phase must be a character vector or string scalar.');
end

phase = lower(strtrim(value));
switch phase
    case {'to','take-off','open'}
        phase = 'takeoff';
    case {'end-of-field','end_of_field'}
        phase = 'eof';
    case {'cr','closed'}
        phase = 'cruise';
end
end

function validateCommand(value)
if ~isscalar(value) || ~isnumeric(value) || ~isreal(value) || ...
        ~isfinite(value) || value < 0 || value > 1
    error('nozzle_command_override must be a real finite scalar in [0,1].');
end
end
