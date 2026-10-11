function [Ps0,P2,T2,V0] = Inlet(H,Ma,deltaT,sigma)
% INLET 进气道
%   此处显示详细说明
% 计算环境静温和静压
if nargin < 4
    sigma = 1;
end
if H <= 11000
    Ts0 = 288.15 + deltaT - 0.0065*H;
    Ps0 = 101325*(1 - 0.225577*10^-4*H)^5.25588;
else
    Ts0 = 216.65 + deltaT;
    Ps0 = 22632*exp((11000 - H)/6341.62);
end
R = T2Gas(Ts0, 0, 4); % 计算气体常数
Cp = T2Gas(Ts0, 0, 1); % 计算比热（容）
k = Cp/(Cp - R); % 计算比热比
V0 = Ma*(k*R*Ts0)^0.5; % 计算进口气流速度
T1 = Ts0*(1 + (k - 1)/2*Ma^2);
P1 = Ps0*(1 + (k - 1)/2*Ma^2)^(k/(k - 1)); % 计算进口总温和总压
P2 = P1*sigma;
T2 = T1; % 计算进气道出口总温和总压
end

