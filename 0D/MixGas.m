function [farmix,Wmain,Tmix,Hmix] = MixGas(Wmain,Hmain,far,Wcool,Hcool)
%MIXCOOL 混合气体计算
%   此处显示详细说明
Hmix = (Wmain*Hmain + Wcool*Hcool)/(Wmain + Wcool); % 计算混合气体焓
farmix = Wmain*far/(1+far)/(Wmain/(1 + far) + Wcool); % 计算混合气体油气比
Tmix = Gas2T(Hmix,farmix,2); % 计算混合气体总温
Wmain = Wmain + Wcool; % 计算混合气体流量
end

