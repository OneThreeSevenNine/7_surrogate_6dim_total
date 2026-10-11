function save_zoom_results_3D(Altitude, Ma, n_step, data, target_n)
%SAVE_ZOOM_RESULTS_3D Write 3-D fields into one existing zoom history column.
% Four-argument calls preserve the legacy timing and write column n_step-1.
% The optional target_n writes an explicit column, used only to complete the
% final converged outer iteration without invoking the next Map_ite step.
if nargin < 5 || isempty(target_n)
    target_n = n_step - 1;
    if target_n < 1
        return
    end
end
validateattributes(target_n,{'numeric'},{'scalar','integer','positive','finite'});
if ~isstruct(data) || ~isscalar(data)
    error('COUPLING:ThreeDData','3-D results must be a scalar structure.');
end

switch IdentifyOperatingPointOTW(Altitude,Ma)
    case 'TO'
        filename = 'zoom_TO.txt';
    case 'EOF'
        filename = 'zoom_EOF.txt';
    case 'CR'
        filename = 'zoom_CR.txt';
    otherwise
        return
end
if exist(filename,'file') ~= 2
    error('COUPLING:MissingZoomHistory','Base history file not found: %s',filename);
end

fid = fopen(filename,'r');
if fid < 0, error('COUPLING:HistoryOpen','Cannot open %s for reading.',filename); end
cleaner = onCleanup(@() fclose(fid));
file_lines = {};
while ~feof(fid)
    line = fgetl(fid);
    if ischar(line), file_lines{end+1} = line; end %#ok<AGROW>
end
clear cleaner
if isempty(file_lines), error('COUPLING:EmptyHistory','History file is empty: %s',filename); end

header = strsplit(file_lines{1},sprintf('\t'));
n_array = cellfun(@str2double,header(2:end));
col_idx = find(n_array==target_n,1,'last')+1;
if isempty(col_idx)
    error('COUPLING:HistoryColumn','Column n=%d was not found in %s.',target_n,filename);
end
num_cols = numel(header);
existing_labels = cell(numel(file_lines),1);
cell_matrix = cell(numel(file_lines),num_cols);
for i=1:numel(file_lines)
    cells = strsplit(file_lines{i},sprintf('\t'));
    existing_labels{i}=cells{1};
    for j=1:num_cols
        if j<=numel(cells), cell_matrix{i,j}=cells{j}; else, cell_matrix{i,j}='NaN'; end
    end
end

labels = fieldnames(data);
for k=1:numel(labels)
    label=labels{k}; value=data.(label);
    if isstring(value)
        if ~isscalar(value), error('COUPLING:ThreeDValue','Field %s must be scalar.',label); end
        value=char(value);
    end
    if ~(ischar(value) || (isnumeric(value) && isscalar(value)))
        error('COUPLING:ThreeDValue','Field %s must be a numeric or character scalar.',label);
    end
    row_idx=find(strcmp(existing_labels,label),1);
    if isempty(row_idx)
        row_idx=size(cell_matrix,1)+1;
        cell_matrix{row_idx,1}=label;
        for j=2:num_cols, cell_matrix{row_idx,j}='NaN'; end
        existing_labels{row_idx,1}=label;
    end
    if ischar(value), cell_matrix{row_idx,col_idx}=value;
    else, cell_matrix{row_idx,col_idx}=sprintf('%.6f',value);
    end
end

fid=fopen(filename,'w');
if fid<0, error('COUPLING:HistoryOpen','Cannot open %s for writing.',filename); end
cleaner=onCleanup(@() fclose(fid));
for i=1:size(cell_matrix,1)
    fprintf(fid,'%s',cell_matrix{i,1});
    for j=2:size(cell_matrix,2), fprintf(fid,'\t%s',cell_matrix{i,j}); end
    fprintf(fid,'\n');
end
clear cleaner
fprintf('[SUCCESS] 3D results written to column n=%d in %s\n',target_n,filename);
end