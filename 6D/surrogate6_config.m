function config = surrogate6_config()
%SURROGATE6_CONFIG Configuration for the pure SVM/RBF coupling workflow.
root = fileparts(mfilename('fullpath'));
config.root = root;
config.project_root = fileparts(root);
config.rbf_dir = fullfile(config.project_root,'RBF');
config.model_file = fullfile(config.rbf_dir,'model','rbf6_model.mat');
config.run_root = fullfile(root,'runs');

config.root_relative_tolerance = 1e-8;
config.root_fallback_relative_tolerance = 3e-3;
config.root_max_iterations = 30;
config.root_max_step_kPa = 2;
config.root_backtrack_trials = 12;
config.min_jacobian_rcond = 1e-10;
config.pressure_ratio_indices = [3 6];

config.input_order = {'Nf','ps_b','ps_c'};
config.output_order = {'w_b','eff_b','pr_b','w_c','eff_c','pr_c'};
end
