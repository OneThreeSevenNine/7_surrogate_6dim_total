%% =========================================================================
% CALCULATION OF SCALE FACTORS FOR DESIGN POINT MAPS (ENGLISH INTERFACE)
% =========================================================================
% Design point parameters (Calculated via GasTurb station data)
% Both fan maps are evaluated with station-2 inlet conditions. The inner
% stream therefore must not use the corrected flow printed at station 21.
W2_tip_cord = W2cor_d;
W2_hub_cord = W21d*Pstd/P2d*sqrt(T2d/Tstd);
FAN_tip_eff_d = 0.8759; FAN_tip_pr_d = 1.340; FAN_tip_ncord = 1; FAN_tip_Rd = 0.5;
FAN_hub_eff_d = 0.7840; FAN_hub_pr_d = 1.439; FAN_hub_ncord = 1; FAN_hub_Rd = 0.4;
W25cord = 27.573; HPC_eff_d = 0.8400; HPC_pr_d = 12.000; HPC_ncord = 1; HPC_Rd = 0.5;
W41cord = 4.998; HPT_eff_d = 0.8800; HPT_pr_d = 3.373; HPT_ncord = 1; HPT_Rd = 0.5;
W45cord = 16.205; LPT_eff_d = 0.9000; LPT_pr_d = 3.365; LPT_ncord = 1.1; LPT_Rd = 0.5;

%% =========================================================================
% LOAD GENERIC COMPONENT MAPS VIA CROSS-PLATFORM PATHS
% =========================================================================
% CRITICAL: Ensure 'Map' folder and all filenames match the exact case in Linux file system
% SubsonicCompressor IPC01
[FAN_tip_mass, FAN_tip_eff, FAN_tip_pr] = readmap(fullfile('.', 'Map', 'LPC01.txt'));
%[FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = readmap(fullfile('.', 'Map', 'SubsonicCompressor.txt'));
[FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = readmap(fullfile('.', 'Map', 'IPC01.txt'));
% [FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = readmap(fullfile('.', 'Map', 'TranssonicCompressor.txt'));
[HPC_mass, HPC_eff, HPC_pr]             = readmap(fullfile('.', 'Map', 'HPC01.txt'));
[HPT_mass, HPT_eff, HPT_pr]             = readmap(fullfile('.', 'Map', 'HPT01.txt'));
[LPT_mass, LPT_eff, LPT_pr]             = readmap(fullfile('.', 'Map', 'LPT01.txt'));

%% =========================================================================
% CALCULATE SCALE FACTORS AND RE-SCALE GENERIC MAPS
% =========================================================================
scale = zeros(5,4); % Pre-allocate for scale matrices: [W, eff, pr, ncord]

[scale(1,:)] = scale_cal(W2_tip_cord,  FAN_tip_eff_d, FAN_tip_pr_d,  FAN_tip_mass, FAN_tip_eff, FAN_tip_pr, FAN_tip_ncord, FAN_tip_Rd);
[scale(2,:)] = scale_cal(W2_hub_cord, FAN_hub_eff_d, FAN_hub_pr_d,  FAN_hub_mass, FAN_hub_eff, FAN_hub_pr, FAN_hub_ncord, FAN_hub_Rd);
[scale(3,:)] = scale_cal(W25cord,      HPC_eff_d,     HPC_pr_d,      HPC_mass,     HPC_eff,     HPC_pr,     HPC_ncord,     HPC_Rd);
[scale(4,:)] = scale_cal(W41cord,      HPT_eff_d,     HPT_pr_d,      HPT_mass,     HPT_eff,     HPT_pr,     HPT_ncord,     HPT_Rd);
[scale(5,:)] = scale_cal(W45cord,      LPT_eff_d,     LPT_pr_d,      LPT_mass,     LPT_eff,     LPT_pr,     LPT_ncord,     LPT_Rd);

[FAN_tip_mass, FAN_tip_eff, FAN_tip_pr] = mapscale(FAN_tip_mass, FAN_tip_eff, FAN_tip_pr, scale(1,:));
[FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = mapscale(FAN_hub_mass, FAN_hub_eff, FAN_hub_pr, scale(2,:));
[HPC_mass, HPC_eff, HPC_pr]             = mapscale(HPC_mass, HPC_eff, HPC_pr, scale(3,:));
[HPT_mass, HPT_eff, HPT_pr]             = mapscale(HPT_mass, HPT_eff, HPT_pr, scale(4,:));
[LPT_mass, LPT_eff, LPT_pr]             = mapscale(LPT_mass, LPT_eff, LPT_pr, scale(5,:));

%% =========================================================================
% SAVE SCALED SCALED ENGINE COMPONENT MAPS
% =========================================================================
savemap(fullfile('.', 'Map', 'FAN_tip_dp.txt'), FAN_tip_mass, FAN_tip_eff, FAN_tip_pr);
savemap(fullfile('.', 'Map', 'FAN_hub_dp.txt'), FAN_hub_mass, FAN_hub_eff, FAN_hub_pr);
savemap(fullfile('.', 'Map', 'HPC_dp.txt'),     HPC_mass,     HPC_eff,     HPC_pr);
savemap(fullfile('.', 'Map', 'HPT_dp.txt'),     HPT_mass,     HPT_eff,     HPT_pr);
savemap(fullfile('.', 'Map', 'LPT_dp.txt'),     LPT_mass,     LPT_eff,     LPT_pr);

fprintf('[INFO] Reference design point component maps scaled and saved successfully.\n');
