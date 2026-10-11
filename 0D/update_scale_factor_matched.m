function update_scale_factor_matched(Altitude,Ma,n,coupling_root)
%UPDATE_SCALE_FACTOR_MATCHED Build Arms.mat from the previous RBF prediction.
if n <= 1, error('COUPLING:Iteration','Matched scale update requires n > 1.'); end
if nargin < 4 || isempty(coupling_root)
    coupling_root = fullfile(fileparts(mfilename('fullpath')),'..','6D','runs');
end
previous = n-1;
zero = read_zero_d_history(Altitude,Ma,previous);
matched_path=fullfile(coupling_root,sprintf('outer_%03d',previous),'matched_result.csv');
if exist(matched_path,'file') ~= 2
    error('COUPLING:MissingMatched', ...
        'Missing RBF matched result for outer iteration %d: %s',previous,matched_path);
end
T=readtable(matched_path);
required={'outer_iter','w_b','eff_b','w_c','eff_c','ps_b_kPa','ps_c_kPa', ...
    'svm_label','in_training_range','in_training_hull','rbf_physical_valid'};
if height(T)~=1 || ~all(ismember(required,T.Properties.VariableNames))
    error('COUPLING:MatchedSchema','matched_result.csv has an invalid schema.');
end
if double(T.outer_iter(1))~=previous
    error('COUPLING:MatchedIteration','matched_result.csv has the wrong outer iteration.');
end
gate=[double(T.svm_label(1)) double(T.in_training_range(1)) ...
    double(T.in_training_hull(1)) double(T.rbf_physical_valid(1))];
if any(gate~=1)
    error('COUPLING:MatchedGate', ...
        'Previous RBF result failed stability, training-domain, or physical-validity checks.');
end

W_tip_RBF=double(T.w_b(1)); eff_tip_RBF=double(T.eff_b(1));
W_hub_RBF=double(T.w_c(1)); eff_hub_RBF=double(T.eff_c(1));
Ps_bypass_RBF=double(T.ps_b_kPa(1)); Ps_core_RBF=double(T.ps_c_kPa(1));
rbf_values=[W_tip_RBF eff_tip_RBF W_hub_RBF eff_hub_RBF ...
    Ps_bypass_RBF Ps_core_RBF];
if any(~isfinite(rbf_values)) || any(rbf_values<=0)
    error('COUPLING:MatchedValues', ...
        'Previous RBF flow, efficiency, or pressure values are invalid.');
end

% Legacy aliases are retained because Map_ite and the zoom history schema use
% the historical *_3D names. Their source in this workflow is exclusively RBF.
W_tip_3D=W_tip_RBF; eff_tip_3D=eff_tip_RBF;
W_hub_3D=W_hub_RBF; eff_hub_3D=eff_hub_RBF;
Ps_bypass_3D=Ps_bypass_RBF; Ps_core_3D=Ps_core_RBF;
W_tip_0D=zero.W_tip_0D; eff_tip_0D=zero.eff_tip_0D;
W_hub_0D=zero.W_hub_0D; eff_hub_0D=zero.eff_hub_0D;
save('Arms.mat','W_tip_0D','eff_tip_0D','W_hub_0D','eff_hub_0D', ...
    'Ps_core_RBF','Ps_bypass_RBF','W_tip_RBF','eff_tip_RBF','W_hub_RBF','eff_hub_RBF', ...
    'Ps_core_3D','Ps_bypass_3D','W_tip_3D','eff_tip_3D','W_hub_3D','eff_hub_3D');
fprintf('[SUCCESS] Loaded outer %d RBF prediction for 0D iteration %d.\n',previous,n);
end

function zero = read_zero_d_history(Altitude,Ma,target_iteration)
switch IdentifyOperatingPointOTW(Altitude,Ma)
    case 'TO', filename='zoom_TO.txt';
    case 'EOF', filename='zoom_EOF.txt';
    case 'CR', filename='zoom_CR.txt';
    otherwise, error('COUPLING:OperatingPoint','No zoom history file for this operating point.');
end
if exist(filename,'file')~=2, error('COUPLING:History','Missing 0D history: %s',filename); end
lines=readlines(filename);
if isempty(lines), error('COUPLING:History','0D history is empty.'); end
header=strsplit(char(lines(1)),sprintf('\t'));
iterations=cellfun(@str2double,header(2:end));
col=find(iterations==target_iteration,1,'last')+1;
if isempty(col), error('COUPLING:HistoryColumn','No 0D history column for iteration %d.',target_iteration); end
wanted={'W13','effFAN_tip','W22','effFAN_hub'};
values=nan(1,4);
for i=2:numel(lines)
    cells=strsplit(char(lines(i)),sprintf('\t'));
    if numel(cells)<col, continue; end
    idx=find(strcmp(wanted,cells{1}),1);
    if ~isempty(idx), values(idx)=str2double(cells{col}); end
end
if any(~isfinite(values)) || any(values<=0)
    error('COUPLING:HistoryValues','Incomplete 0D flow/efficiency data for iteration %d.',target_iteration);
end
zero.W_tip_0D=values(1); zero.eff_tip_0D=values(2);
zero.W_hub_0D=values(3); zero.eff_hub_0D=values(4);
end