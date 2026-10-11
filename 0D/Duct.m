function [Pout] = Duct(sigmad,W,P,T,Wd,Pd,Td)
%DUCT 计算总压恢复系数和总压，适用于管道和其他部件
%   此处显示详细说明
sigma = 1 - (1 - sigmad)*((W*T^0.5/P)/(Wd*Td^0.5/Pd))^2; % 计算总压恢复系数
Pout = P*sigma; % 计算总压
end

