% OTW geared mixed-flow turbofan: steady component matching
tic;
close all;clc;
clearvars -except n coupling_root ;
%     Altitude Ma DeltaT NH PWX flight_phase nozzle_command_override;

if ~exist('n','var')
    n = input('Please enter current iteration count (n>0): ');
end
if ~exist('coupling_root','var') || isempty(coupling_root)
    coupling_root = fullfile(fileparts(mfilename('fullpath')),'..','6D','runs');
end
txt_speed_file = 'NL.txt';

Altitude = 0;
Ma = 0;
DeltaT = 17.35;
NH = 13160;
PWX = 0;
% 'cruise', 'takeoff', 'climb', 'descent', 'landing'    
flight_phase = 'takeoff'; 
% 0: no override, 1: override with nozzle_command_override
nozzle_command_override = 1;

[nozzleCommand,flightPhase,operatingPoint] = ResolveNozzleCommandOTW( ...
    Altitude,Ma,flight_phase,nozzle_command_override);

if n == 1
    update_design_data();
    update_map_dp();
    run(fullfile('.','Design_data.m'));
    run(fullfile('.','Map_dp.m'));
elseif n > 1
    update_scale_factor_matched(Altitude,Ma,n,coupling_root);
    run(fullfile('.','Design_data.m'));
    run(fullfile('.','Map_ite.m'));
else
    error('Iteration count n must be positive.');
end
save(fullfile('.','Design_data.mat'));
%% x = [far,Nfan,RfanOuter,RfanInner,RHPC,RHPT,RLPT]
Ini_x = [0.9023/29.902,3860,0.5,0.4,0.5,0.5,0.5]';
xmin = [0.005,2000,0.02,0.02,0.02,0.02,0.02]';
xmax = [0.060,5000,1.98,1.98,1.98,1.98,1.98]';
residual = 1e-4;
it_max = 100;
x = min(max(Ini_x,xmin),xmax);
trace_x = nan(it_max+1,numel(x));
trace_error = nan(it_max+1,numel(x));

[Error,errmonitor] = Component(Altitude,Ma,DeltaT,NH,PWX,x,...
    nozzleCommand,residual,0,it_max);
trace_x(1,:) = x';
trace_error(1,:) = Error';

for it = 1:it_max
    if norm(Error,inf) < residual
        break
    end
    
    J = zeros(numel(Error),numel(x));
    for j = 1:numel(x)
        step = max(abs(x(j))*1e-4,1e-6);
        xPert = x;
        xPert(j) = min(xmax(j),xPert(j)+step);
        actualStep = xPert(j)-x(j);
        if actualStep == 0
            xPert(j) = max(xmin(j),x(j)-step);
            actualStep = xPert(j)-x(j);
        end
        Epert = Component(Altitude,Ma,DeltaT,NH,PWX,xPert,...
            nozzleCommand,residual,it,it_max);
        J(:,j) = (Epert-Error)/actualStep;
    end
    
    dx = -pinv(J)*Error;
    oldNorm = norm(Error,2);
    accepted = false;
    alpha = 1;
    for trial = 1:8
        xTrial = min(max(x+alpha*dx,xmin),xmax);
        [Etrial,monitorTrial] = Component(Altitude,Ma,DeltaT,NH,PWX,...
            xTrial,nozzleCommand,residual,it,it_max);
        if all(isfinite(Etrial)) && norm(Etrial,2) < oldNorm
            x = xTrial;
            Error = Etrial;
            errmonitor = monitorTrial;
            accepted = true;
            break
        end
        alpha = alpha/2;
    end
    
    if ~accepted
        warning('Newton line search stalled at iteration %d.',it);
        break
    end
    trace_x(it+1,:) = x';
    trace_error(it+1,:) = Error';
    fprintf('Iteration %3d: max|residual| = %.3e, alpha = %.4f\n',...
        it,norm(Error,inf),alpha);
end

% Force the final station data to be written even for a non-converged case.
[Error,errmonitor] = Component(Altitude,Ma,DeltaT,NH,PWX,x,...
    nozzleCommand,residual,it_max,it_max);
load(fullfile('.','stations.mat'));
converged = norm(Error,inf) < residual;

fprintf('\n========== OTW matching result ==========\n');
fprintf('Converged       : %d\n',converged);
fprintf('Max residual    : %.6e\n',norm(Error,inf));
fprintf('Error monitor   : %d\n',errmonitor);
fprintf('W2/W2 corrected : %.3f / %.3f kg/s\n',W2,W2cor);
fprintf('BPR             : %.4f\n',BPR);
fprintf('Fan PR out/in   : %.4f / %.4f\n',prFAN_tip,prFAN_hub);
fprintf('Fan eff out/in  : %.4f / %.4f\n',effFAN_tip,effFAN_hub);
fprintf('Rfan Outer/Inner: %.4f / %.4f\n',RfanOuter,RfanInner);
fprintf('T4              : %.2f K\n',T4);
fprintf('FN              : %.3f kN\n',FN);
fprintf('TSFC            : %.4f g/(kN*s)\n',TSFC);
fprintf('Wf              : %.4f kg/s\n',Wf);
fprintf('Nfan / NLPT     : %.1f / %.1f rpm\n',Nfan,NLPT);
fprintf('NH controlled   : %.1f rpm\n',NH);
fprintf('Mixer Mach h/c  : %.4f / %.4f\n',M63,M163);
fprintf('M64 / M8        : %.4f / %.4f\n',M64,M8);
fprintf('Operating point : %s\n',operatingPoint);
fprintf('Flight phase    : %s\n',flightPhase);
fprintf('Nozzle command  : %.3f\n',nozzleCommand);
fprintf('A8 geom / eff   : %.5f / %.5f m^2\n',A8use,A8effUse);
fprintf('CD8 used        : %.5f\n',CD8use);
fprintf('LPerr           : %.5f\n',LPerr);
fprintf('T2 / P2         : %.3f / %.3f \n',T2,P2);
fprintf('W13 / T13 /P13  : %.3f / %.3f / %.3f \n',W13,T13,P13);
fprintf('PR16 /P16       : %.3f / %.3f\n',P16/P13,P16);
fprintf('T21 / P21       : %.3f / %.3f\n',T21,P21);
fprintf('LPT eff / PR    : %.3f / %.3f\n',effLPT,prLPT);
fprintf('W8              : %.3f\n',W8);

results = struct();
results.n = n;
results.BPR = BPR;
results.x = x;
results.xNames = {'far','Nfan','RfanOuter','RfanInner',...
    'RHPC','RHPT','RLPT'};
results.T4 = T4;
results.FN = FN;
results.TSFC = TSFC;
results.NL = Nfan;       % Legacy label: fan shaft speed
results.Nfan = Nfan;
results.NLPT = NLPT;
results.NH = NH;
results.Wf = Wf;
results.T2 = T2; results.P2 = P2; results.W2 = W2; results.W2cor = W2cor;
results.T13 = T13; results.P13 = P13; results.W13 = W13; results.W13cor = W13cor;
results.T21 = T21; results.P21 = P21; results.W22 = W22; results.W22cor = W22cor;
results.effFAN_tip = effFAN_tip; results.prFAN_tip = prFAN_tip;
results.effFAN_hub = effFAN_hub; results.prFAN_hub = prFAN_hub;
results.P64 = P64; results.T64 = T64; results.W64 = W64;
results.M63 = M63; results.M163 = M163; results.M64 = M64; results.M8 = M8;
results.operatingPoint = operatingPoint;
results.flightPhase = flightPhase;
results.nozzleCommand = nozzleCommand;
results.A8 = A8use; results.A8eff = A8effUse; results.CD8 = CD8use;
results.PgearLoss = PgearLoss;

save_zoom_results_0D(Altitude,Ma,results);
write_outer_target(results,coupling_root);

fid = fopen(txt_speed_file,'w');
if fid == -1
    error('Unable to write fan speed file: %s',txt_speed_file);
end
fprintf(fid,'%.4f\n',Nfan);
fclose(fid);
toc;
