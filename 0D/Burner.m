function [W4,P4,T4,H4] = Burner(W3,T3,P3,far,Hu,sigmad,Effd,W3d,P3d,T3d)
%BURNER 燃烧室
%   此处显示详细说明
[P4] = Duct(sigmad,W3,P3,T3,W3d,P3d,T3d); % 计算燃烧室出口总压
Wf = W3*far; % 计算燃油流量
W4 = Wf + W3; % 计算燃烧室出口流量
Hin = T2Gas(T3,0,2); % 计算燃烧室进口空气总焓
Eff = 1-(1 - Effd)*((W3/(P3^1.8*exp(T3/300)))/(W3d/(P3d^1.8*exp(T3d/300))))^1.6; % 计算燃烧室效率
% if Eff < 0 | (~isreal(Eff)) 
%     Eff = 0;
% end
H4 = (Wf*Hu*Eff + W3*Hin + 331.33*10^3*Wf)/W4; % 计算燃烧室出口燃气总焓，此处不加331.33*10^3*Wf会偏小，因为gasturb考虑了进口燃油焓
T4 = Gas2T(H4,far,2); % 计算燃烧出口总温
end

