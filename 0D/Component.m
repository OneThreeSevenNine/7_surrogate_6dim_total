function [Error,errmonitor] = Component(Altitude,Ma,DeltaT,NH,PWX,Ini_x,...
    nozzleCommand,residual,it,it_max)
%COMPONENT OTW geared mixed-flow turbofan component matching model.
% x = [far,Nfan,RfanOuter,RfanInner,RHPC,RHPT,RLPT]

errmonitor = 0;
load('Design_data.mat');

far = Ini_x(1);
Nfan = Ini_x(2);
RfanOuter = Ini_x(3);
RfanInner = Ini_x(4);
RHPC = Ini_x(5);
RHPT = Ini_x(6);
RLPT = Ini_x(7);
NLPT = GearRatio*Nfan;

%% Inlet and dual-stream fan rotor
[Ps0,P2,T2,V0] = Inlet(Altitude,Ma,DeltaT,sigmaInlet);
H2 = T2Gas(T2,0,2);
[W2,W2cor,effFAN_tip,prFAN_tip,P13,T13,H13,Ncor_FAN_tip] = ...
    Compressor(Nfan,P2,T2,H2,Nfan_d,T2d,Pstd,Tstd,...
    FAN_tip_mass,FAN_tip_eff,FAN_tip_pr,RfanOuter);
[W21,W21cor,effFAN_hub,prFAN_hub,P21,T21,H21,Ncor_FAN_hub] = ...
    Compressor(Nfan,P2,T2,H2,Nfan_d,T2d,Pstd,Tstd,...
    FAN_hub_mass,FAN_hub_eff,FAN_hub_pr,RfanInner);   

W13 = W2-W21;
W13cor = W13*Pstd/P13*sqrt(T13/Tstd);
PWFAN = W13*(H13-H2) + W21*(H21-H2);

%% Bypass OGV/fan-frame duct, 13 -> 16
P16 = Duct(sigma13d,W13,P13,T13,W13d,P13d,T13d);
T16 = T13;
W16 = W13*(1-leakage_bypass);

%% Inner stator and gooseneck, 21=22, 22->24 lossless, 24->25 duct
P22 = P21; T22 = T21; H22 = H21; W22 = W21; W22cor = W21cor;
P24 = P22; T24 = T22; H24 = H22; W24 = W22;
P25 = Duct(sigma24d,W24,P24,T24,W24d,P24d,T24d);
T25 = T24; H25 = H24;

%% HPC and secondary-air system
[W25,W25cor,effHPC,prHPC,P3,T3,H3,Ncor_HPC] = ...
    Compressor(NH,P25,T25,H25,NHd,T25d,Pstd,Tstd,...
    HPC_mass,HPC_eff,HPC_pr,RHPC);
[WH1,TH1,HH1,PWH1] = cool_bleed(Hr1,Hx1,W25,prHPC,effHPC,T25,H25,H3,1);
[WH2,TH2,HH2,PWH2] = cool_bleed(Hr2,Hx2,W25,prHPC,effHPC,T25,H25,H3,1);
[WH3,TH3,HH3,PWH3] = cool_bleed(Hr3,Hx3,W25,prHPC,effHPC,T25,H25,H3,1);
[WH4,TH4,HH4,PWH4] = cool_bleed(Hr4,Hx4,W25,prHPC,effHPC,T25,H25,H3,1);
[WH5,~,~,PWH5] = cool_bleed(ovboard_bleed_r,ovboard_bleed_x,...
    W25,prHPC,effHPC,T25,H25,H3,1);
W3 = W25-WH3-WH4-WH5;
W31 = W3-WH1-WH2;
T31 = T3; P31 = P3;
PWHPC = W31*(H3-H25) + PWH1+PWH2+PWH3+PWH4+PWH5;

%% Combustor and HP turbine
[W4,P4,T4,H4] = Burner(W31,T31,P31,far,Hu,sigm31d,...
    EffBurnd,W31d,P31d,T31d);
Wf = W4-W31;
[far1,W41,T41,H41] = MixGas(W4,H4,far,WH1,HH1);
P41 = P4;
[W43,W43cor,effHPT,prHPT,P43,T43,H43,Ncor_HPT] = ...
    Turbine(NH,P41,T41,H41,far1,NHd,T41d,Pstd,Tstd,...
    HPT_mass,HPT_eff,HPT_pr,RHPT);
PWHPT = W41*H41-W43*H43;

[far2,W44,T44,H44] = MixGas(W43,H43,far1,WH2,HH2);
P44 = P43;
[far3,W45,T45,H45] = MixGas(W44,H44,far2,WH3,HH3);
P45 = Duct(sigma44d,W44,P44,T44,W44d,P44d,T44d);

%% Geared LP turbine
[W49,W49cor,effLPT,prLPT,P49,T49,H49,Ncor_LPT] = ...
    Turbine(NLPT,P45,T45,H45,far3,NLPT_d,T45d,Pstd,Tstd,...
    LPT_mass,LPT_eff,LPT_pr,RLPT);
PWLPT = W45*H45-W49*H49;
[far4,W5,T5,H5] = MixGas(W49,H49,far3,WH4,HH4);
P5 = P49;
P6 = Duct(sigma5d,W5,P5,T5,W5d,P5d,T5d);
T6 = T5; W6 = W5;

%% Mixer inlet ducts and static-pressure matching
P63 = Duct(sigma63d,W6,P6,T6,W6d,P6d,T6d);
T63 = T6; W63 = W6;
P163 = Duct(sigma163d,W16,P16,T16,W16d,P16d,T16d);
T163 = T16; W163 = W16;

cold = struct('W',W163,'Pt',P163,'Tt',T163,'far',0);
hot = struct('W',W63,'Pt',P63,'Tt',T63,'far',far4);
geom = struct('ACold',A163,'AHot',A63,'A64',A64,...
    'CDCold',1,'CDHot',1,'CD64',1,'sigmaPt',sigmaMixerPt);
[mix,mixerStatus] = MixerOTW(cold,hot,geom);
if mixerStatus ~= 0
    errmonitor = 10+mixerStatus;
end
W64 = mix.W; P64 = mix.Pt; T64 = mix.Tt; H64 = mix.Ht; far64 = mix.far;
M63 = mix.MHot; M163 = mix.MCold; M64 = mix.M64;
Ps63 = mix.PsHot; Ps163 = mix.PsCold;

%% Variable-area D-shaped mixed nozzle
[A8use,CD8use,A8effUse] = NozzleAreaScheduleOTW(nozzleCommand,A8,CD8,...
    A8geomTOref,A8geomCRref,A8effTOref,A8effCRref);
[T8,V8,W8,Fgross8,M8,nozzleChoked,Ps8] = ...
    NozzleOTW(A8use,CD8use,CFG8,Ps0,far64,P64,T64);
FN = (Fgross8-W2*V0)/1000;
TSFC = 1000*Wf/max(FN,eps); % g/(kN*s)

%% Matching residuals
Error = zeros(7,1);
Error(1) = mix.pressureResidual;
Error(2) = W25/max(W24,eps)-1;
Error(3) = W43/max(W41,eps)-1;
Error(4) = W49/max(W45,eps)-1;
Error(5) = W8/max(W64,eps)-1;
Error(6) = PWHPT*etaHPshaft/max(PWHPC+PWX,eps)-1;
Error(7) = PWLPT*etaLPshaft*etaGear/max(PWFAN,eps)-1;
% Error(7) = W2cor/max(W2cor_d,eps)-1;

PgearOut = PWLPT*etaLPshaft*etaGear;
PgearLoss = PWLPT*etaLPshaft*(1-etaGear);
BPR = W13/max(W21,eps);
LPerr = PWLPT*etaLPshaft*etaGear/max(PWFAN,eps)-1;

if any(~isfinite(Error)) || ~isreal(Error)
    Error(:) = 1e3;
    errmonitor = 99;
end

if all(abs(Error)<residual) || it >= it_max-1
    save('stations.mat');
end
end
