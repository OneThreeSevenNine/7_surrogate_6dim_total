function save_zoom_results_0D(Altitude, Ma, data)
% SAVE_SIMULATION_RESULTS 自动化将0D仿真结果保存至txt文件（非破坏拓扑+回滚裁剪版）
% 功能：
%   1. 支持0D数据覆盖更新，自动保留和继承3D函数在下方创建的任何新行
%   2. Decode the five OTW map-line coordinates stored in data.x.
%   3. 【完美修复】自动识别当前 n，若文本中存在 >n 的历史列，自动裁剪并剔除

    %% 1. 动态文件名判断
    isValidCondition = true;
    switch IdentifyOperatingPointOTW(Altitude,Ma)
        case 'TO'
            filename = 'zoom_TO.txt';
        case 'EOF'
            filename = 'zoom_EOF.txt';
        case 'CR'
            filename = 'zoom_CR.txt';
        otherwise
            isValidCondition = false;
    end

    if ~isValidCondition
        return;
    end

    %% 2. 准备标准0D行标签列表
    labels_0D = { ...
        'n'; 'operatingPoint'; 'flightPhase'; ...
        'BPR'; 'RfanOuter'; 'RfanInner'; 'RHPC'; 'RHPT'; 'RLPT'; ...
        'T4'; 'FN'; 'TSFC'; 'NL'; 'Nfan'; 'NLPT'; 'NH'; 'Wf'; ...
        'T2'; 'P2'; 'W2'; 'W2cor'; ...
        'T13'; 'P13'; 'W13'; 'W13cor'; ...
        'T21'; 'P21'; 'W22'; 'W22cor'; ...
        'effFAN_tip'; 'prFAN_tip'; 'effFAN_hub'; 'prFAN_hub'; ...
        'nozzleCommand'; 'A8'; 'A8eff'; 'CD8' ...
    };
    
    %% 3. 从传入的数据中动态提取/解离数值
    vals_0D = cell(length(labels_0D), 1);
    for i = 1:length(labels_0D)
        curr_field = labels_0D{i};
        
        if isfield(data, curr_field)
            vals_0D{i} = data.(curr_field);
        elseif isfield(data, 'x') && ...
               (strcmp(curr_field, 'RfanOuter') || strcmp(curr_field, 'RfanInner') || ...
                strcmp(curr_field, 'RHPC') || strcmp(curr_field, 'RHPT') || ...
                strcmp(curr_field, 'RLPT'))
            if strcmp(curr_field, 'RfanOuter'),      vals_0D{i} = data.x(3);
            elseif strcmp(curr_field, 'RfanInner'), vals_0D{i} = data.x(4);
            elseif strcmp(curr_field, 'RHPC'),      vals_0D{i} = data.x(5);
            elseif strcmp(curr_field, 'RHPT'),      vals_0D{i} = data.x(6);
            elseif strcmp(curr_field, 'RLPT'),      vals_0D{i} = data.x(7);
            end
        else
            try
                vals_0D{i} = evalin('base', curr_field);
            catch
                vals_0D{i} = NaN;
            end
        end
    end
    current_n = data.n;

    %% 4. 如果文件不存在，进行首次初始化创建
    if ~exist(filename, 'file')
        fid = fopen(filename, 'w');
        fprintf(fid, 'n\t%.1f\n', current_n);
        for i = 2:length(labels_0D)
            fprintf(fid, '%s\t%s\n', labels_0D{i}, ...
                formatResultValue(labels_0D{i},vals_0D{i}));
        end
        fclose(fid);
        return;
    end

    %% 5. 如果文件已存在，读取并解析其二维矩阵
    fid = fopen(filename, 'r');
    file_lines = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline)
            file_lines{end+1} = tline; %#ok<AGROW>
        end
    end
    fclose(fid);

    if isempty(file_lines)
        return;
    end

    % 解析列头（第一行 'n' 所在的行）
    first_line_cells = strsplit(file_lines{1}, '\t');
    orig_num_cols = length(first_line_cells);
    n_array = zeros(1, orig_num_cols-1);
    for j = 2:orig_num_cols
        n_array(j-1) = str2double(first_line_cells{j});
    end

    %% 6. 【核心修复逻辑：历史回滚裁剪】
    % 检查是否存在大于 current_n 的列，寻找有效列的边界
    valid_col_flags = [true, n_array <= current_n]; % 第一列变量名永远有效
    keep_col_indices = find(valid_col_flags);        % 需要保留的列索引数组
    
    % 检查当前 current_n 是否已经在保留的列中存在
    n_array_trimmed = n_array(n_array <= current_n);
    col_idx = find(n_array_trimmed == current_n, 1, 'last') + 1;
    
    % 如果不存在（即 current_n 是一个全新的单调递增步），则在右侧扩充一列
    if isempty(col_idx)
        keep_col_indices = [keep_col_indices, length(valid_col_flags) + 1]; %#ok<AGROW>
        col_idx = length(keep_col_indices);
    end
    
    % 确定裁剪/扩充后的最终总列数
    num_final_cols = length(keep_col_indices);

    %% 7. 提取旧行标签，并基于【裁剪后的新拓扑】重建单元胞缓存矩阵
    existing_labels = cell(length(file_lines), 1);
    cell_matrix = cell(length(file_lines), num_final_cols);
    
    for i = 1:length(file_lines)
        line_cells = strsplit(file_lines{i}, '\t');
        existing_labels{i} = line_cells{1};
        
        % 只提取需要保留的列，淘汰掉 >n 的那一列
        for j = 1:num_final_cols
            old_col_pos = keep_col_indices(j);
            if old_col_pos <= length(line_cells)
                cell_matrix{i, j} = line_cells{old_col_pos};
            else
                if i == 1
                    cell_matrix{i, j} = sprintf('%.1f', current_n); % 列头填入新n
                else
                    cell_matrix{i, j} = 'NaN'; % 其余新列填入 NaN
                end
            end
        end
    end

    %% 8. 精准覆盖更新当前 0D 行的数据
    for k = 1:length(labels_0D)
        curr_label = labels_0D{k};
        curr_val = vals_0D{k};
        
        row_idx = find(strcmp(existing_labels, curr_label), 1);
        if isempty(row_idx)
            cell_matrix{end+1, 1} = curr_label; %#ok<AGROW>
            for j = 2:num_final_cols, cell_matrix{end, j} = 'NaN'; end
            row_idx = size(cell_matrix, 1);
            existing_labels{end+1, 1} = curr_label; %#ok<AGROW>
        end
        
        % 写入 0D 数据
        cell_matrix{row_idx, col_idx} = formatResultValue(curr_label,curr_val);
    end

    %% 9. 重新写回文本文件
    fid = fopen(filename, 'w');
    for i = 1:size(cell_matrix, 1)
        fprintf(fid, '%s', cell_matrix{i,1});
        for j = 2:size(cell_matrix, 2)
            fprintf(fid, '\t%s', cell_matrix{i,j});
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
end

function valueText = formatResultValue(label,value)
if isstring(value)
    if ~isscalar(value)
        error('Result field %s must be a string scalar.',label);
    end
    valueText = char(value);
elseif ischar(value)
    valueText = value;
elseif strcmp(label,'n') || strcmp(label,'NL') || ...
        strcmp(label,'Nfan') || strcmp(label,'NLPT') || strcmp(label,'NH')
    valueText = sprintf('%.1f',value);
else
    valueText = sprintf('%.6f',value);
end
end
