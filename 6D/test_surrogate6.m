function test_surrogate6()
%TEST_SURROGATE6 Function and CSV integration tests for the pure surrogate.
config=surrogate6_config();
addpath(config.rbf_dir);
loaded=load(config.model_file,'model');
model=loaded.model;

% A classifier-accepted training point must be an admissible exact target.
[~,~,training_info]=surrogate6_predict(model,model.rbf.X);
usable=find(training_info.is_usable & training_info.in_training_range & ...
    training_info.in_training_hull,1,'first');
assert(~isempty(usable),'The frozen model has no admissible retained training point.');
x0=model.rbf.X(usable,:);
[y0,~,info0]=surrogate6_predict(model,x0);
assert(info0.stable_label==1 && info0.physical_valid);
assert(info0.in_training_range && info0.in_training_hull);
[pressure,diagnostic]=surrogate6_solve_root( ...
    model,x0(1),y0(config.pressure_ratio_indices),x0(2:3),config);
assert(strcmp(diagnostic.solution_mode,'EXACT_STABLE_RBF_ROOT'));
assert(diagnostic.max_relative_residual<=config.root_relative_tolerance);
assert(max(abs(pressure-x0(2:3)))<1e-9);

% With Newton disabled, a nearby target exercises the <=0.3% fallback path.
fallback_config=config;
fallback_config.root_max_iterations=0;
fallback_target=y0(config.pressure_ratio_indices).*[1.001 0.999];
[~,fallback]=surrogate6_solve_root( ...
    model,x0(1),fallback_target,x0(2:3),fallback_config);
assert(fallback.used_best_fallback);
assert(fallback.max_relative_residual<=config.root_fallback_relative_tolerance);

% A speed beyond the training range cannot produce an admissible root.
outside_speed=model.rbf.xmax(1)+0.1*model.rbf.span(1);
failed=false;
try
    surrogate6_solve_root(model,outside_speed, ...
        y0(config.pressure_ratio_indices),x0(2:3),config);
catch ME
    failed=strcmp(ME.identifier,'SURROGATE6:RootFailure');
end
assert(failed,'An out-of-range speed was not rejected.');

% Exercise the published CSV interface and the four independent residuals.
run_root=tempname;
outer_path=fullfile(run_root,'outer_001');
mkdir(outer_path);
outer_iter=1; %#ok<NASGU>
Nf_rpm=x0(1); %#ok<NASGU>
pr_b_target=y0(3); %#ok<NASGU>
pr_c_target=y0(6); %#ok<NASGU>
w_b_0d=y0(1); %#ok<NASGU>
eff_b_0d=y0(2); %#ok<NASGU>
w_c_0d=y0(4); %#ok<NASGU>
eff_c_0d=y0(5); %#ok<NASGU>
target=table(outer_iter,Nf_rpm,pr_b_target,pr_c_target, ...
    w_b_0d,eff_b_0d,w_c_0d,eff_c_0d);
writetable(target,fullfile(outer_path,'outer_target.csv'));
result=surrogate6_main(1,run_root);
assert(strcmp(result.status,'CONVERGED'));
matched=readtable(fullfile(outer_path,'matched_result.csv'));
required={'w_b','eff_b','pr_b','w_c','eff_c','pr_c','solution_mode', ...
    'svm_label','in_training_range','in_training_hull','rbf_physical_valid'};
assert(height(matched)==1 && all(ismember(required,matched.Properties.VariableNames)));
outer=evaluate_outer_convergence(1,run_root,1e-3);
assert(strcmp(outer.status,'CONVERGED'));
assert(max(abs(outer.residuals))<1e-8);

% A malformed target must fail before a matched result is published.
bad_path=fullfile(run_root,'outer_002');
mkdir(bad_path);
bad_target=table(2,x0(1),'VariableNames',{'outer_iter','Nf_rpm'});
writetable(bad_target,fullfile(bad_path,'outer_target.csv'));
failed=false;
try
    surrogate6_main(2,run_root);
catch ME
    failed=strcmp(ME.identifier,'SURROGATE6:TargetSchema');
end
assert(failed && exist(fullfile(bad_path,'matched_result.csv'),'file')~=2);
assert(strcmp(strtrim(fileread(fullfile(bad_path,'surrogate_status.txt'))),'FAILED'));

fprintf('[PASS] Pure surrogate tests passed. Temporary output: %s\n',run_root);
end
