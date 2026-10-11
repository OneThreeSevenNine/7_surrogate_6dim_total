%% OTW geared mixed-flow turbofan design data (SL static, ISA +17.35 K)
Pstd = 101325;
Tstd = 288.15;

%% Shaft system
Nfan_d = 3860;              % rpm, fan shaft
GearRatio = 2.062;          % NLPT/Nfan
NLPT_d = GearRatio*Nfan_d;  % rpm, LPT shaft
NHd = 14000;                % rpm, HP shaft
etaGear = 0.977;
etaLPshaft = 0.977;
etaHPshaft = 0.99;

%% Fan and inlet
T2d = 305.50;
P2d = 99299;
sigmaInlet = 0.9800;
W2d = 386.933;
W2cor_d =  406.542;
W13d = 352.074;
W21d = 34.859;

% Bypass OGV/fan-frame duct, station 13 -> 16
sigma13d = 0.9900;
P13d = 133031;
T13d = 335.79;
P16d = 131701;
T16d = 335.79;
W16d = W13d;

% Station 21 and 22 coincide. Station 24 -> 25 is the gooseneck duct.
sigma24d = 0.9850;
W24d = 34.859;
P24d = 142938;
T24d = 348.09;
T25d = 348.09;

%% Core
Hu = 43.124e6;
sigm31d = 0.95;
EffBurnd = 0.9995;
W31d = 29.979;
P31d = 1689523;
T31d = 757.85;
Wfd = 0.9004;

T41d = 1697.44;
sigma44d = 0.9900;
W44d = 34.713;
P44d = 475882;
T44d = 1307.58;
T45d = 1291.81;

% LPT exit duct, station 5 -> 6
sigma5d = 0.98500;
W5d = 35.759;
P5d = 139992;
T5d = 1000.42;
W6d = 35.759;
P6d = 137893;
T6d = 1000.42;

%% Mixer, stations 6/16 -> 63/163 -> 64
sigma63d = 0.995;
sigma163d = 0.995;
M63d = 0.55037;
M163d = 0.46772;
M64d = 0.50000;
A64 = 1.97634;
P64d = 130758;
T64d = 402.77;
W64d = 387.833;

P63d = sigma63d*P6d;
P163d = sigma163d*P16d;
far6d = Wfd/(W6d-Wfd);

Cp63d = T2Gas(T6d,far6d,1);
R63d = T2Gas(T6d,far6d,4);
gamma63d = Cp63d/(Cp63d-R63d);
Cp163d = T2Gas(T16d,0,1);
R163d = T2Gas(T16d,0,4);
gamma163d = Cp163d/(Cp163d-R163d);

A63 = W6d*sqrt(T6d)/(P63d*massFlowParameter(M63d,gamma63d,R63d));
A163 = W16d*sqrt(T16d)/(P163d*massFlowParameter(M163d,gamma163d,R163d));
PtWeighted_d = (W6d*P63d + W16d*P163d)/(W6d+W16d);
sigmaMixerPt = P64d/PtWeighted_d;

%% Variable-area D-shaped mixed nozzle
% A8 and CD8 remain the calibrated takeoff/open values imported from the
% GasTurb design point. The report values below define only the relative
% cruise-to-takeoff schedule so that the existing 0D calibration is kept.
A8 = 1.81892;
CD8 = 0.97000;
CFG8 = 0.995;

% OTW Final Design Report: geometric areas (Section 14) and cycle effective
% areas (Section 5). Side doors open at takeoff and close for cruise.
A8geomTOref = 1.8451576;     % m^2, 2860 in^2
A8geomCRref = 1.5;     % m^2, 2420 in^2
% A8geomCRref = 1.5612872;     % m^2, 2420 in^2
A8effTOref = 1.80193088;     % m^2, 2793 in^2
A8effCRref = 1.5;     % m^2, 2307 in^2
% A8effCRref = 1.48838412;     % m^2, 2307 in^2

%% Secondary-air system
Hx1 = 1.0; Hr1 = 0.05;
Hx2 = 1.0; Hr2 = 0.06;
Hx3 = 0.6; Hr3 = 0.02;
Hx4 = 0.7; Hr4 = 0.01;
ovboard_bleed_x = 1;
ovboard_bleed_r = 0;
leakage_bypass = 0;
