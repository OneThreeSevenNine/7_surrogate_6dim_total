%% =========================================================================
% COMPUTE SCALE FACTORS FROM 0D AND SVM/RBF COUPLING RESULTS
% =========================================================================
load("Arms.mat")

%% Introduce relaxation factors
if n > 2
    omega_w_tip = 0.1;
    omega_eff_tip = 0.1;
    omega_w_hub = 0.05;
    omega_eff_hub = 0.1;
else  
    omega_w_tip = 0.1;
    omega_eff_tip = 0.2;
    omega_w_hub = 0.1;
    omega_eff_hub = 0.1;
end

W_total_0D = W_tip_0D + W_hub_0D;
f_tip_W = (1 + (W_tip_3D / W_tip_0D - 1) * omega_w_tip);
f_hub_W = (1 + (W_hub_3D / W_hub_0D - 1) * omega_w_hub);
f_tip_eff = (eff_tip_3D - eff_tip_0D) * omega_eff_tip;
f_hub_eff = (eff_hub_3D - eff_hub_0D) * omega_eff_hub;
W_total_0D_relaxed = W_tip_0D*f_tip_W + W_hub_0D*f_hub_W;
f_total_W = W_total_0D_relaxed/W_total_0D;

%% Re-scale mass flow and efficiency only
scale = zeros(2,4); % Columns: [W, eff, pr, ncord]
scale(1,:) = [f_total_W, f_tip_eff, 1, 1.0]; 
scale(2,:) = [f_hub_W, f_hub_eff, 1, 1.0];
fprintf('f_total_W f_tip_eff f_hub_W f_hub_eff = %.4f %.4f %.4f %.4f\n', [scale(1,1:2), scale(2,1:2)]);

% Reference design constants
W25cord = 27.637; HPC_eff_d = 0.8400; HPC_pr_d = 12.200; HPC_ncord = 1; HPC_Rd = 0.5;
W41cord = 4.943; HPT_eff_d = 0.8800; HPT_pr_d = 3.387; HPT_ncord = 1; HPT_Rd = 0.5;
W45cord = 16.088; LPT_eff_d = 0.9000; LPT_pr_d = 3.427; LPT_ncord = 1.1; LPT_Rd = 0.5;

%% =========================================================================
% LOAD SCALED MAPS VIA LINUX COMPATIBLE PATHS
% =========================================================================
% CRITICAL FIX: Replaced all '.\Map\...' backslashes with cross-platform fullfile
[FAN_tip_mass, FAN_tip_eff, FAN_tip_pr] = readmap(fullfile('.', 'Map', 'FAN_tip_dp.txt'));
[FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = readmap(fullfile('.', 'Map', 'FAN_hub_dp.txt'));
[HPC_mass, HPC_eff, HPC_pr]             = readmap(fullfile('.', 'Map', 'HPC_dp.txt'));
[HPT_mass, HPT_eff, HPT_pr]             = readmap(fullfile('.', 'Map', 'HPT_dp.txt'));
[LPT_mass, LPT_eff, LPT_pr]             = readmap(fullfile('.', 'Map', 'LPT_dp.txt'));

% Execute multi-component iterative scaling
[FAN_tip_mass, FAN_tip_eff, FAN_tip_pr] = map_scale_ite(FAN_tip_mass, FAN_tip_eff, FAN_tip_pr, scale(1,:));
[FAN_hub_mass, FAN_hub_eff, FAN_hub_pr] = map_scale_ite(FAN_hub_mass, FAN_hub_eff, FAN_hub_pr, scale(2,:));

%% =========================================================================
% SAVE UPDATED COMPONENT MAPS
% =========================================================================
savemap(fullfile('.', 'Map', 'FAN_tip_dp.txt'), FAN_tip_mass, FAN_tip_eff, FAN_tip_pr);
savemap(fullfile('.', 'Map', 'FAN_hub_dp.txt'), FAN_hub_mass, FAN_hub_eff, FAN_hub_pr);

%% =========================================================================
% PACK AND EXPORT SURROGATE RESIDUAL DATA FOR LEGACY ZOOM HISTORY
% =========================================================================
% A_main_performance_func returns both static pressures in kPa.
results_3D.Ps_core_3D = Ps_core_3D;
results_3D.Ps_bypass_3D = Ps_bypass_3D;
results_3D.W13_3D = W_tip_3D;
results_3D.effFAN_tip_3D = eff_tip_3D;
results_3D.W22_3D = W_hub_3D;
results_3D.effFAN_hub_3D = eff_hub_3D;
results_3D.W_3D = W_hub_3D + W_tip_3D;
results_3D.BPR_3D = W_tip_3D / W_hub_3D;
results_3D.e_W_tip = (W_tip_3D - W_tip_0D) / W_tip_0D;
results_3D.e_eff_tip = (eff_tip_3D - eff_tip_0D) / eff_tip_0D;
results_3D.e_W_hub = (W_hub_3D - W_hub_0D) / W_hub_0D;
results_3D.e_eff_hub = (eff_hub_3D - eff_hub_0D) / eff_hub_0D;
results_3D.omega_W_tip = omega_w_tip;
results_3D.omega_eff_tip = omega_eff_tip;
results_3D.omega_W_hub = omega_w_hub;
results_3D.omega_eff_hub = omega_eff_hub;
results_3D.f_tip_W = f_tip_W;
results_3D.f_tip_eff = f_tip_eff;
results_3D.f_hub_W = f_hub_W;
results_3D.f_hub_eff = f_hub_eff;

try
    current_altitude = evalin('base', 'Altitude');
    current_ma       = evalin('base', 'Ma');
catch
    current_altitude = 0; 
    current_ma       = 0; 
end
save_zoom_results_3D(current_altitude, current_ma, n, results_3D);

%% =========================================================================
% WRITE LATEST RESIDUALS TO e.txt FOR SHELL SCRIPT EVALUATION
% =========================================================================
txt_filename = 'e.txt';
fid = fopen(txt_filename, 'w'); 

if fid ~= -1
    if n == 1
        fprintf(fid, '%d\t%d\t%d\t%d', 1, 1, 1, 1);
    else
        fprintf(fid, '%.8f\t%.8f\t%.8f\t%.8f', ...
            results_3D.e_W_tip, ...
            results_3D.e_eff_tip, ...
            results_3D.e_W_hub, ...
            results_3D.e_eff_hub);
    end
    fclose(fid);
    fprintf('[SUCCESS] Relative residuals successfully written to %s\n', txt_filename);
else
    warning('Unable to open or overwrite file: %s', txt_filename);
end
