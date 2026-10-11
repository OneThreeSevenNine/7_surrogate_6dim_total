function [W,Wcor,eff,pr,Pout,Tout,Hout,Ncor] = Turbine(N,Pin,Tin,Hin,far,Nd,Td,Pstd,Tstd,massMap,effMap,prMap,R)
%TURBINE 涡轮部件
%   此处显示详细说明
Ncor = (N/Tin^0.5)/(Nd/Td^0.5); % 计算相对换算转速
[Wcor,eff,pr] = interpMap(massMap,effMap,prMap,Ncor,R); % 特性图插值
W = Wcor*Pin/Pstd*(Tstd/Tin)^0.5; % 换算流量转换为实际流量
Sin = T2Gas(Tin,far,3); % 计算进口熵函数
Souti = Sin - log10(pr); % 计算出口理想熵函数，涡轮是-
Touti = Gas2T(Souti,far,3); % 计算出口理想总温
Houti = T2Gas(Touti,far,2); % 计算出口理想总焓
Hout = Hin + (Houti - Hin)*eff; % 计算出口总焓，涡轮是*效率
Tout = Gas2T(Hout,far,2); % 计算出口总温
Pout = Pin/pr; % 计算出口总压
end

