function update_map_ite()
    % 文件路径设置
    m_filename = 'Map_ite.m';
    txt_filename = 'OTW_gasturb_dp_1750_3D.txt';
    out_filename = 'Map_ite.m'; % 输出新文件，防止覆盖原文件

    %% 1. 解析 TXT 文件，建立变量映射字典
    fid_txt = fopen(txt_filename, 'r');
    if fid_txt == -1
        error('无法打开文件: %s，请检查文件是否存在。', txt_filename);
    end
    
    % 创建字典，存储 "需要替换的变量名" -> "新数值"
    varMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    
    while ~feof(fid_txt)
        line = fgetl(fid_txt);
        
        % ---------------------------------------------------------
        % 匹配 (1) 站点数据：提取 WRstd (换算流量)
        % ---------------------------------------------------------
        tokens_st = regexp(line, '^\s*(\d+)\s+([\d\.Ee\+\-]+)\s+[\d\.Ee\+\-]+\s+[\d\.Ee\+\-]+\s+([\d\.Ee\+\-]+)', 'tokens');
        if ~isempty(tokens_st)
            st = tokens_st{1}{1};          % 站号
            wrstd_val = tokens_st{1}{3};   % WRstd (换算流量)
            
            switch st
                case '25'
                    varMap('W25cord') = wrstd_val;
                case '41'
                    varMap('W41cord') = wrstd_val;
                case '45'
                    varMap('W45cord') = wrstd_val;
            end
        end
        
        % ---------------------------------------------------------
        % 匹配 (2) 部件效率和压比数据：提取 isentr 和 P/P
        % ---------------------------------------------------------
        tokens_comp = regexp(line, '(HP Compressor|HP Turbine|LP Turbine)\s+([\d\.Ee\+\-]+)\s+[\d\.Ee\+\-]+\s+[\d\.Ee\+\-]+\s+([\d\.Ee\+\-]+)', 'tokens');
        if ~isempty(tokens_comp)
            comp = tokens_comp{1}{1};      % 部件名称
            isentr_val = tokens_comp{1}{2}; % isentr
            pr_val = tokens_comp{1}{3};     % P/P
            
            switch comp
                case 'HP Compressor'
                    varMap('HPC_eff_d')     = isentr_val;
                    varMap('HPC_pr_d')      = pr_val;
                case 'HP Turbine'
                    varMap('HPT_eff_d')     = isentr_val;
                    varMap('HPT_pr_d')      = pr_val;
                case 'LP Turbine'
                    varMap('LPT_eff_d')     = isentr_val;
                    varMap('LPT_pr_d')      = pr_val;
            end
        end
    end
    fclose(fid_txt);
    
    %% 2. 读取 M 文件并进行逐行多变量替换
    fid_m = fopen(m_filename, 'r');
    if fid_m == -1
        error('无法打开文件: %s，请检查文件是否存在。', m_filename);
    end
    
    m_lines = {};
    keys_list = keys(varMap);
    updated_count = 0;
    
    while ~feof(fid_m)
        line = fgetl(fid_m);
        
        % 遍历字典中的每一个待替换变量
        for i = 1:length(keys_list)
            varName = keys_list{i};
            new_val = varMap(varName);
            
            % 使用正则：匹配独立单词 (varName) + 等号 + 数字
            pattern = ['\<', varName, '\>\s*=\s*[\d\.Ee\+\-]+'];
            
            if ~isempty(regexp(line, pattern, 'once'))
                line = regexprep(line, pattern, [varName, ' = ', new_val]);
                updated_count = updated_count + 1;
                fprintf('已更新: %-15s -> %s\n', varName, new_val);
            end
        end
        m_lines{end+1} = line; %#ok<AGROW> 
    end
    fclose(fid_m);
    
    %% 3. 将更新后的内容写入新文件
    fid_out = fopen(out_filename, 'w');
    for i = 1:length(m_lines)
        fprintf(fid_out, '%s\n', m_lines{i});
    end
    fclose(fid_out);
    
    fprintf('\n----- 替换完成！共更新了 %d 个参数 -----\n', updated_count);
    fprintf('新代码已保存至: %s\n', out_filename);
end
