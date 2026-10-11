function [mass,eff,pr] = readmap(mapname)
% READMAP 读取特性图txt文件，需要为GasTurb格式
%   此处显示详细说明
% original = readmatrix('HPT02.txt'); % LPT01导入不成功，无法识别前几行，=加上空格后可以识别，测试发现十分玄学，很多情况识别不了
original = importdata(mapname); % .map改为.txt
A = original'; % reshape是竖着读，为了横着读，转置
A = reshape(A,1,[]);  % 重组矩阵为一行
A = A(~isnan(A)); % 删除读进来时产生的非数字NAN
row = fix(A(1,1)); % 对表头值，fix截尾取整，得到特性图行数，即转速线个数
column = round((A(1,1) - row)*1000); % 得到特性图列数，即R值个数，此处使用round是四舍五入，使用fix有时会产生.9999
if row == 2 % 涡轮特性图
    pr = A(1:2*row*column); % 取出涡轮压比数据
    pr = reshape(pr,column,[]); % 重组
    pr = pr'; % 转置
    pr(3,:) = []; % 删除涡轮压比表重复的一行转速
    pr(2,1) = 0; % 涡轮R值赋值
    pr(3,1) = 1; % 涡轮R值赋值
    pr = pr'; % 再转置，涡轮压比情况特殊
    A(1:2*row*column) = []; % 删除压比数据
    row = fix(A(1,1)); % 得到涡轮流量、效率表的行数，即转速线个数
    column = round((A(1,1) - row)*1000); % 得到涡轮流量、效率表的列数，即R值个数
    mass = A(1:row*column); % 取出涡轮流量表数据
    mass = reshape(mass,column,[]);
    mass = mass';
    A(1:row*column) = []; % 删除流量数据，得到效率表数据
    eff = A(1:row*column);
    eff = reshape(eff,column,[]);
    eff = eff';
else % 压气机特性图，流量、效率、压比三个表的格式一样
    mass = A(1:row*column);
    mass = reshape(mass,column,[]);
    mass = mass';
    A(1:row*column) = [];
    eff = A(1:row*column);
    eff = reshape(eff,column,[]);
    eff = eff';
    A(1:row*column) = [];
    pr = A(1:row*column);
    pr = reshape(pr,column,[]);
    pr = pr';
end


end

