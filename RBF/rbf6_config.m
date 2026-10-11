function c = rbf6_config()
% Standard nine-column source layout: rpm, kPa, kPa, then six CFD outputs.
c.base_dir = fileparts(mfilename('fullpath'));
c.train_file = fullfile(c.base_dir,'rbf_6 train.txt');
c.test_file = fullfile(c.base_dir,'rbf_6_test.txt');
c.train_rows = 315; c.test_rows = 131; c.data_schema_version = 2;
c.seed = 20261007; c.folds = 5;
c.box_candidates = [0.1 1 10 100];
c.scale_candidates = [0.1 0.3 1 3];
c.lambda_candidates = [0 1e-10 1e-8 1e-6 1e-4 1e-2];
c.min_rcond = 1e-12; c.domain_tolerance = 1e-10;
c.input_names = {'Nf','ps_b','ps_c'};
c.input_units = {'rpm','kPa','kPa'};
c.output_names = {'w_b','eff_b','pr_b','w_c','eff_c','pr_c'};
c.output_units = {'kg/s','1','1','kg/s','1','1'};
c.label_reference_rows = 165;
c.label_reference_usable_count = 163;
c.label_margin_fraction = 0.05;
c.efficiency_bounds = [0.5 1];
c.pressure_ratio_min = 1;
c.label_rule = ['finite outputs; speed-interpolated w_b/w_c envelope calibrated from ' ...
    'the first 165 training rows with 5% span margin; 0.5<eff_b,eff_c<1; pr_b,pr_c>1'];
c.inlet_conditions = struct('T_K',305.5,'p_kPa',99.29);
c.speed_nodes = [3088 3281 3474 3667 3860 4053];
end
