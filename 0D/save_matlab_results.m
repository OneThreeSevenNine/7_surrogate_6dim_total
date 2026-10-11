function save_matlab_results(Altitude,Ma,data)
%SAVE_MATLAB_RESULTS Save the principal OTW 0D result for known conditions.
operatingPoint = IdentifyOperatingPointOTW(Altitude,Ma);
switch operatingPoint
    case 'TO'
        filename = 'Matlab_TO.txt';
    case 'EOF'
        filename = 'Matlab_EOF.txt';
    case 'CR'
        filename = 'Matlab_CR.txt';
    otherwise
        return
end

fid = fopen(filename,'w');
if fid == -1
    error('Unable to create %s.',filename);
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'operatingPoint\t%s\n',data.operatingPoint);
fprintf(fid,'flightPhase\t%s\n',data.flightPhase);
fields = {'BPR','T4','FN','TSFC','Nfan','NLPT','NH','Wf','T2','P2',...
    'W2','W2cor','T13','P13','W13','W13cor','T21','P21','W22','W22cor',...
    'effFAN_tip','prFAN_tip','effFAN_hub','prFAN_hub','P64','T64','W64',...
    'M63','M163','M64','M8','nozzleCommand','A8','A8eff','CD8','PgearLoss'};
for k = 1:numel(fields)
    name = fields{k};
    fprintf(fid,'%s\t%.9g\n',name,data.(name));
end
fprintf(fid,'RfanOuter\t%.9g\n',data.x(3));
fprintf(fid,'RfanInner\t%.9g\n',data.x(4));
fprintf(fid,'RHPC\t%.9g\n',data.x(5));
fprintf(fid,'RHPT\t%.9g\n',data.x(6));
fprintf(fid,'RLPT\t%.9g\n',data.x(7));
end
