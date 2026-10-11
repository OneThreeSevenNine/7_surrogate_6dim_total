function update_design_data()
    % 文件路径设置（请确保这两个文件在当前 MATLAB 工作目录下）
    m_filename = 'Design_data.m';
    txt_filename = 'OTW_gasturb_dp_1750_3D.txt';
    out_filename = 'Design_data.m'; % 输出的新文件名，防止直接覆盖原文件

    %% 1. 解析 TXT 文件，建立变量映射字典
    fid_txt = fopen(txt_filename, 'r');
    if fid_txt == -1
        error('无法打开文件: %s，请检查文件是否存在。', txt_filename);
    end
    
    % 创建字典，存储 "变量名" -> "新数值"
    varMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    extraVarNameMap = containers.Map( ...
        {'WF', 'XM63', 'XM163', 'XM64', 'P2/P1', 'P16/P13', 'P25/P24', 'P45/P44', 'P6/P5'}, ...
        {'Wfd', 'M63d', 'M163d', 'M64d', 'sigmaInlet', 'sigma13d', 'sigma24d', 'sigma44d', 'sigma5d'});
    
    while ~feof(fid_txt)
        line = fgetl(fid_txt);
        
        % 匹配站点数据：格式为 [站号] [W] [T] [P] ...
        % 例如: "  13    293.452    331.36   153.648   207.523"
        tokens_station = regexp(line, '^\s*(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)', 'tokens');
        if ~isempty(tokens_station)
            st = tokens_station{1}{1}; % 站号
            w_val = tokens_station{1}{2}; % 流量 W
            t_val = tokens_station{1}{3}; % 温度 T
            
            % 压力 P 转换：从 kPa 换算为 Pa (*1000)
            p_val = num2str(str2double(tokens_station{1}{4}) * 1000, '%.0f'); 
            
            % 存入字典，按 m 文件中的命名规则拼接后缀 'd'
            varMap(['W', st, 'd']) = w_val;
            varMap(['T', st, 'd']) = t_val;
            varMap(['P', st, 'd']) = p_val;
        end
        
        % 匹配面积 A 数据，例如 "A8 = 0.26179 m²"
        tokens_A = regexp(line, 'A(\d+)\s*=\s*([\d\.]+)', 'tokens');
        if ~isempty(tokens_A)
            st = tokens_A{1}{1};
            varMap(['A', st]) = tokens_A{1}{2};
        end
        
        % 匹配流量系数 CD 数据，例如 "CD8 = 0.97935"
        tokens_CD = regexp(line, 'CD(\d+)\s*=\s*([\d\.]+)', 'tokens');
        if ~isempty(tokens_CD)
            st = tokens_CD{1}{1};
            varMap(['CD', st]) = tokens_CD{1}{2};
        end

        % 匹配燃油流量 WF 数据，例如 "WF = 0.9023 kg/s"
        tokens_WF = regexp(line, 'WF\s*=\s*([\d\.Ee\+\-]+)', 'tokens');
        if ~isempty(tokens_WF)
            varMap(extraVarNameMap('WF')) = tokens_WF{1}{1};
        end

        % 匹配马赫数 XM 数据，例如 "XM63 = 0.52933"
        tokens_XM = regexp(line, '(XM\d+)\s*=\s*([\d\.Ee\+\-]+)', 'tokens');
        for i = 1:length(tokens_XM)
            txtName = tokens_XM{i}{1};
            if isKey(extraVarNameMap, txtName)
                varMap(extraVarNameMap(txtName)) = tokens_XM{i}{2};
            end
        end

        % 匹配总压恢复/压比数据，例如 "P25/P24=0.9850"
        tokens_sigma = regexp(line, '(P\d+/P\d+)\s*=\s*([\d\.Ee\+\-]+)', 'tokens');
        for i = 1:length(tokens_sigma)
            txtName = tokens_sigma{i}{1};
            if isKey(extraVarNameMap, txtName)
                varMap(extraVarNameMap(txtName)) = tokens_sigma{i}{2};
            end
        end
    end
    fclose(fid_txt);
    
    disp('----- 已成功从 txt 中提取以下所需更新的变量 -----');
    keys_list = keys(varMap);
    % 为了控制台不刷屏，这里不全部打印，提取步骤已完成
    
    %% 2. 读取 M 文件并进行替换
    fid_m = fopen(m_filename, 'r');
    if fid_m == -1
        error('无法打开文件: %s，请检查文件是否存在。', m_filename);
    end
    
    m_lines = {};
    updated_count = 0;
    
    while ~feof(fid_m)
        line = fgetl(fid_m);
        
        % 匹配 m 文件中的变量赋值行，例如 "W13d =  300.209 ;  % 备注"
        % 解析出变量名 (如 W13d)
        tokens_m = regexp(line, '^\s*([a-zA-Z0-9_]+)\s*=\s*[\d\.Ee\+\-]+', 'tokens');
        
        if ~isempty(tokens_m)
            varName = tokens_m{1}{1};
            
            % 如果当前变量在我们提取的 TXT 字典中
            if isKey(varMap, varName)
                new_val = varMap(varName);
                % 使用正则仅替换 "=" 后面的数字部分，保留分号和注释
                line = regexprep(line, '(=)\s*[\d\.Ee\+\-]+', ['$1 ', new_val]);
                updated_count = updated_count + 1;
                fprintf('更新变量: %-6s -> %s\n', varName, new_val);
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
    
    fprintf('\n----- 替换完成！共更新了 %d 个变量 -----\n', updated_count);
    fprintf('新代码已保存至: %s\n', out_filename);
end
