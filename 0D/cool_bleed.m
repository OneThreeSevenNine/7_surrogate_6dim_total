function [W_bleed,T_bleed,H_bleed,PW_bleed] = cool_bleed(r,x,Wcomp,pr,eff,Tin,Hin,Hout,option)
% COOL_BLEED 引气
%   此处显示详细说明
if option == 1 % 压气机引气计算
    W_bleed = Wcomp*r; % 引气流量为压气机流量乘以引气系数
    H_bleed = Hin + (Hout - Hin)*x; % 引气气流焓值等于进口焓+相对焓（位置）乘以压气机进出口焓差
    T_bleed = Gas2T(H_bleed,0,2);
    PW_bleed = W_bleed*(H_bleed - Hin);
elseif option == 2

end

end

