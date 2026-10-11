function [mix,status] = MixerOTW(cold,hot,geom)
%MIXEROTW Static-pressure matching model for the OTW mixed exhaust.
% cold/hot fields: W, Pt, Tt, far. geom fields: ACold, AHot, A64,
% CDCold, CDHot, CD64, sigmaPt.

mix = struct();
status = 0;

[gammaCold,RCold] = gasConstants(cold.Tt,cold.far);
[gammaHot,RHot] = gasConstants(hot.Tt,hot.far);
[MCold,capCold,okCold] = solveSubsonicMach(cold.W,geom.ACold,...
    geom.CDCold,cold.Pt,cold.Tt,gammaCold,RCold);
[MHot,capHot,okHot] = solveSubsonicMach(hot.W,geom.AHot,...
    geom.CDHot,hot.Pt,hot.Tt,gammaHot,RHot);

if ~okCold
    MCold = 1;
    status = 1;
end
if ~okHot
    MHot = 1;
    status = 1;
end

PsCold = cold.Pt/(1 + 0.5*(gammaCold-1)*MCold^2)^(gammaCold/(gammaCold-1));
PsHot = hot.Pt/(1 + 0.5*(gammaHot-1)*MHot^2)^(gammaHot/(gammaHot-1));

HCold = T2Gas(cold.Tt,cold.far,2);
HHot = T2Gas(hot.Tt,hot.far,2);
W64 = cold.W + hot.W;
H64 = (cold.W*HCold + hot.W*HHot)/W64;
Wfuel = cold.W*cold.far/(1+cold.far) + hot.W*hot.far/(1+hot.far);
Wair = W64-Wfuel;
far64 = Wfuel/Wair;
T64 = Gas2T(H64,far64,2);
PtWeighted = (cold.W*cold.Pt + hot.W*hot.Pt)/W64;
P64 = geom.sigmaPt*PtWeighted;

[gamma64,R64] = gasConstants(T64,far64);
[M64,cap64,ok64] = solveSubsonicMach(W64,geom.A64,geom.CD64,...
    P64,T64,gamma64,R64);
if ~ok64
    status = status+2;
    M64 = 1;
end

mix.W = W64;
mix.Tt = T64;
mix.Pt = P64;
mix.Ht = H64;
mix.far = far64;
mix.MCold = MCold;
mix.MHot = MHot;
mix.M64 = M64;
mix.PsCold = PsCold;
mix.PsHot = PsHot;
mix.capacityCold = capCold;
mix.capacityHot = capHot;
mix.capacity64 = cap64;
mix.pressureResidual = (PsHot-PsCold)/(0.5*(PsHot+PsCold));
if status ~= 0
    mix.pressureResidual = mix.pressureResidual + ...
        sign(mix.pressureResidual+eps)*invalidResidual(capCold,capHot,cap64);
end
end

function [gamma,R] = gasConstants(Tt,far)
Cp = T2Gas(Tt,far,1);
R = T2Gas(Tt,far,4);
gamma = Cp/(Cp-R);
end

function r = invalidResidual(capCold,capHot,cap64)
r = 1 + max([0,capCold-1,capHot-1,cap64-1]);
end
