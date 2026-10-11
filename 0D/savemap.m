function savemap(filename, mass, eff, pr)
    % SAVEMAP 将特性图数据保存为符合 readmap.m 逻辑的 GasTurb 格式
    % 支持压气机（三个标准块）和涡轮（压比块+流量块+效率块）
    fid = fopen(filename, 'w');
    if fid == -1, error('无法创建文件: %s', filename); end
    % 获取压比表的 row 值
    row_pr = size(pr, 2) - 1;
    if row_pr == 2
        %% --- 涡轮模式 (Turbine Mode) --- 
        % 压比 -> 流量 -> 效率
        writeTurbinePRBlock(pr);
        writeStandardBlock(mass);
        writeStandardBlock(eff);
    else
        %% --- 压气机模式 (Compressor Mode) --- 
        % 流量 -> 效率 -> 压比
        writeStandardBlock(mass);
        writeStandardBlock(eff);
        writeStandardBlock(pr);
    end
    fclose(fid);
    fprintf('特性图已成功保存至: %s\n', filename);

    %% --- 内部函数 A：写入标准数据块  ---
    function writeStandardBlock(matrix)
        num_rows = size(matrix, 1) ; 
        num_cols = size(matrix, 2) ;
        header = num_rows + num_cols/1000;
        
        % 写入表头及 R 值坐标
        fprintf(fid, '%16.9f  ', header);
        r_coords = matrix(1, 2:end);
        for i = 1:length(r_coords)
            if mod(i, 5) == 0, fprintf(fid, '\n'); end
            fprintf(fid, '%16.9f  ', r_coords(i));
        end
        
        % 写入等转速线数据
        for r = 2:size(matrix, 1)
            fprintf(fid, '\n');
            line_data = matrix(r, :);
            for i = 1:length(line_data)
                fprintf(fid, '%16.9f  ', line_data(i));
                if mod(i, 5) == 0 && i ~= length(line_data), fprintf(fid, '\n'); end
            end
        end
        fprintf(fid, '\n\n');
    end

    %% --- 内部函数 B：写入涡轮专用压比块 --- 
    function writeTurbinePRBlock(matrix_pr)
        matrix_pr = matrix_pr';
        num_cols = size(matrix_pr, 2);
        header = 2.0 + num_cols/1000; % 固定 row = 2
        
        fprintf(fid, '%12.9f ', header);
        r_coords = matrix_pr(1, 2:end);
        for i = 1:length(r_coords)
            fprintf(fid, '%12.9f ', r_coords(i));
            if mod(i+1, 5) == 0, fprintf(fid, '\n  '); end
        end

        r = 2;
        fprintf(fid, '\n  ');
        line_data = matrix_pr(r, :);
        for i = 1:length(line_data)
            fprintf(fid, '%12.9f ', line_data(i));
            if mod(i, 5) == 0 && i ~= length(line_data), fprintf(fid, '\n  '); end
        end
        fprintf(fid, '\n\n');

        fprintf(fid, '%12.9f ', header);
        r_coords = matrix_pr(1, 2:end);
        for i = 1:length(r_coords)
            fprintf(fid, '%12.9f ', r_coords(i));
            if mod(i+1, 5) == 0, fprintf(fid, '\n  '); end
        end
        
        r = 3;
        fprintf(fid, '\n  ');
        line_data = matrix_pr(r, :);
        for i = 1:length(line_data)
            fprintf(fid, '%12.9f ', line_data(i));
            if mod(i, 5) == 0 && i ~= length(line_data), fprintf(fid, '\n  '); end
        end
        fprintf(fid, '\n\n');
    end
end
