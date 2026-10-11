function save_converged_outer_to_zoom(Altitude, Ma, outer_iter, run_root)
%SAVE_CONVERGED_OUTER_TO_ZOOM Complete the final converged zoom history column.
% This function records the final RBF data without calling Map_ite. Fields
% that would only exist after another map update are intentionally NaN.

validateattributes(outer_iter,{'numeric'},{'scalar','integer','positive','finite'});
if ~(ischar(run_root) || (isstring(run_root) && isscalar(run_root)))
    error('COUPLING:RunRoot','run_root must be a character vector or string scalar.');
end
run_root=char(run_root);
outer_dir=fullfile(run_root,sprintf('outer_%03d',outer_iter));

target=read_single_row(fullfile(outer_dir,'outer_target.csv'), ...
    {'outer_iter','Nf_rpm','pr_b_target','pr_c_target','w_b_0d','eff_b_0d','w_c_0d','eff_c_0d'});
matched=read_single_row(fullfile(outer_dir,'matched_result.csv'), ...
    {'outer_iter','ps_b_kPa','ps_c_kPa','w_b','eff_b','pr_b','w_c','eff_c','pr_c'});
residual=read_single_row(fullfile(outer_dir,'outer_residual.csv'), ...
    {'outer_iter','e_W_tip','e_eff_tip','e_W_hub','e_eff_hub','converged'});

iteration_values=[numeric_scalar(target,'outer_iter') ...
    numeric_scalar(matched,'outer_iter') numeric_scalar(residual,'outer_iter')];
if any(iteration_values ~= outer_iter)
    error('COUPLING:FinalIteration', ...
        'Final CSV outer_iter values [%g %g %g] do not match requested iteration %d.', ...
        iteration_values(1),iteration_values(2),iteration_values(3),outer_iter);
end
if numeric_scalar(residual,'converged') ~= 1
    error('COUPLING:FinalNotConverged', ...
        'outer_residual.csv does not mark outer iteration %d as converged.',outer_iter);
end

% Reading and checking all target fields prevents a stale or incomplete target
% file from being accepted even though only the iteration number is saved.
target_values=[numeric_scalar(target,'Nf_rpm') numeric_scalar(target,'pr_b_target') ...
    numeric_scalar(target,'pr_c_target') numeric_scalar(target,'w_b_0d') ...
    numeric_scalar(target,'eff_b_0d') numeric_scalar(target,'w_c_0d') ...
    numeric_scalar(target,'eff_c_0d')];
matched_values=[numeric_scalar(matched,'ps_b_kPa') numeric_scalar(matched,'ps_c_kPa') ...
    numeric_scalar(matched,'w_b') numeric_scalar(matched,'eff_b') ...
    numeric_scalar(matched,'pr_b') numeric_scalar(matched,'w_c') ...
    numeric_scalar(matched,'eff_c') numeric_scalar(matched,'pr_c')];
residual_values=[numeric_scalar(residual,'e_W_tip') numeric_scalar(residual,'e_eff_tip') ...
    numeric_scalar(residual,'e_W_hub') numeric_scalar(residual,'e_eff_hub')];
if any(~isfinite(target_values)) || any(target_values <= 0) || ...
        any(~isfinite(matched_values)) || any(matched_values <= 0) || ...
        any(~isfinite(residual_values))
    error('COUPLING:FinalValues', ...
        'Final target, matched RBF, or residual values are invalid.');
end

results_3D.W13_3D=matched_values(3);
results_3D.effFAN_tip_3D=matched_values(4);
results_3D.prFAN_tip_3D=matched_values(5);
results_3D.W22_3D=matched_values(6);
results_3D.effFAN_hub_3D=matched_values(7);
results_3D.prFAN_hub_3D=matched_values(8);
results_3D.W_3D=matched_values(3)+matched_values(6);
results_3D.BPR_3D=matched_values(3)/matched_values(6);
results_3D.Ps_bypass_3D=matched_values(1);
results_3D.Ps_core_3D=matched_values(2);
results_3D.e_W_tip=residual_values(1);
results_3D.e_eff_tip=residual_values(2);
results_3D.e_W_hub=residual_values(3);
results_3D.e_eff_hub=residual_values(4);

% No subsequent Map_ite is run after convergence, so these values were never
% calculated or applied for the final column.
results_3D.omega_W_tip=NaN;
results_3D.omega_eff_tip=NaN;
results_3D.omega_W_hub=NaN;
results_3D.omega_eff_hub=NaN;
results_3D.f_tip_W=NaN;
results_3D.f_tip_eff=NaN;
results_3D.f_hub_W=NaN;
results_3D.f_hub_eff=NaN;

save_zoom_results_3D(Altitude,Ma,outer_iter,results_3D,outer_iter);
fprintf('[SUCCESS] Final converged RBF result saved for outer iteration %d.\n',outer_iter);
end

function T=read_single_row(path,required)
if exist(path,'file') ~= 2
    error('COUPLING:MissingFinalFile','Required final result file is missing: %s',path);
end
T=readtable(path);
if height(T) ~= 1 || ~all(ismember(required,T.Properties.VariableNames))
    error('COUPLING:FinalSchema', ...
        '%s must contain exactly one row and all required named columns.',path);
end
end

function value=numeric_scalar(T,name)
value=T.(name);
if ~isnumeric(value) && ~islogical(value)
    error('COUPLING:FinalSchema','Column %s must be numeric.',name);
end
if ~isscalar(value) || ~isreal(value)
    error('COUPLING:FinalSchema','Column %s must contain one real scalar.',name);
end
value=double(value);
end
