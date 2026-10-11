function [scale] = scale_cal(Wcord, effd, prd, massMap, effMap, prMap, ncord, Rd)
% SCALE_CAL 计算设计点的特性图缩放系数
%   此处显示详细说明
scale = zeros(1,4);
scale(1,4) = ncord;  % 为什么转速缩放因子是这样的？
[Wcor, eff, pr] = interpMap(massMap, effMap, prMap, ncord, Rd); % 特性图插值
scale(1,1) = Wcord/Wcor;
% fprintf('风扇换算流量 Wcord = %.3f kg/s\n', Wcord);
% fprintf('风扇流量 Wcor = %.3f kg/s\n', Wcor);
scale(1,2) = effd/eff;
scale(1,3) = (prd - 1)/(pr - 1);
end

