%% 这是一个单独运行的后处理脚本：Post_Process_Main.m
clear; clc;
convert_single_zoom('zoom_CR.txt');
% my_files = {'zoom_TO.txt', 'zoom_EOF.txt', 'zoom_CR.txt'};
% for k = 1:length(my_files)
%     if exist(my_files{k}, 'file') == 2
%         convert_single_zoom(my_files{k});
%     end
% end
disp('所有指定工况的 Excel 报表已在当前文件夹下成功生成。');

function convert_single_zoom(txt_filename)
% CONVERT_SINGLE_ZOOM 将指定的 zoom_XX.txt 计算结果历史文本转换为 Excel (.xlsx) 
% 输入参数:
%   txt_filename - 字符串，带后缀的完整TXT文件名（例如: 'zoom_CR.txt', 'zoom_EOF.txt'）
% 使用示例:
%   convert_single_zoom('zoom_CR.txt');
    fprintf('====== 航空发动机仿真后处理：单文件 TXT -> Excel 转换 ======\n');
    %% 1. 安全拦截与防御性校验
    if nargin < 1 || isempty(txt_filename)
        error('错误：请输入需要转换的 TXT 历史文件名。输入示例：convert_single_zoom(''zoom_CR.txt'')');
    end
    if exist(txt_filename, 'file') ~= 2
        error('错误：在当前工作路径下未找到文件 "%s"，请检查拼写或切换 MATLAB 当前路径。', txt_filename);
    end
    %% 2. 动态提取文件名并生成目标 .xlsx 后缀名
    [file_path, file_name, ~] = fileparts(txt_filename);
    if isempty(file_path)
        xlsx_filename = [file_name, '.xlsx'];
    else
        xlsx_filename = fullfile(file_path, [file_name, '.xlsx']);
    end
    fprintf('正在解析源文本: %s \n', txt_filename);
    %% 3. 读取文本文件的所有行
    fid = fopen(txt_filename, 'r');
    file_lines = {};
    while ~feof(fid)
        tline = fgetl(fid);
        if ischar(tline) && ~isempty(strtrim(tline))
            file_lines{end+1} = tline; %#ok<AGROW>
        end
    end
    fclose(fid);
    if isempty(file_lines)
        fprintf('[WARNING] 文件 %s 内容为空，取消转换。\n', txt_filename);
        return;
    end
    %% 4. 自适应拆分列头，动态构建数据拓扑
    % 采用连续空格/Tab自适应切分逻辑，完美化解列与列之间空格不均匀带来的错位
    first_line_cells = strsplit(strtrim(file_lines{1}));
    num_cols = length(first_line_cells);
    num_rows = length(file_lines);
    excel_cell_data = cell(num_rows, num_cols);
    %% 5. 逐行读取、清洗并实现字符向纯数值的“智能化脱壳”
    for i = 1:num_rows
        curr_cells = strsplit(strtrim(file_lines{i}));
        excel_cell_data{i, 1} = curr_cells{1};
        for j = 2:num_cols
            if j <= length(curr_cells)
                val_str = curr_cells{j};
                val_num = str2double(val_str);
                if isnan(val_num) && ~strcmp(val_str, 'NaN')
                    excel_cell_data{i, j} = val_str; 
                elseif strcmp(val_str, 'NaN')
                    excel_cell_data{i, j} = 'NaN';   % 3D暂未覆盖的计算空位保持字符 'NaN'
                else
                    excel_cell_data{i, j} = val_num; 
                end
            else
                excel_cell_data{i, j} = 'NaN'; % 越界保护补位
            end
        end
    end

    %% 6. 执行覆盖式的 Excel 文件写入
    try
        if exist(xlsx_filename, 'file') == 2
            delete(xlsx_filename);
        end
        warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');
        output_table = cell2table(excel_cell_data(2:end, :), 'VariableNames', excel_cell_data{1, :});
        writetable(output_table, xlsx_filename, 'WriteRowNames', false);        
    catch
        if exist(xlsx_filename, 'file') == 2, delete(xlsx_filename); end
        writecell(excel_cell_data, xlsx_filename);
    end

    fprintf('[SUCCESS] 转换成功！Excel报告已保存至: %s \n\n', xlsx_filename);
end