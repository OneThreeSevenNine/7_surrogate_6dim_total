function write_outer_target(results, coupling_root)
%WRITE_OUTER_TARGET Export one explicit 0D target for the 2-D inner loop.
required = {'n','Nfan','prFAN_tip','prFAN_hub','W13','effFAN_tip','W22','effFAN_hub'};
if ~all(isfield(results,required))
    error('COUPLING:TargetFields','0D results are missing fields required by the 2-D interface.');
end
values = [results.n results.Nfan results.prFAN_tip results.prFAN_hub ...
    results.W13 results.effFAN_tip results.W22 results.effFAN_hub];
if any(~isfinite(values)) || any(values <= 0)
    error('COUPLING:TargetValues','0D target contains a non-finite or non-positive value.');
end
outer_dir = fullfile(coupling_root,sprintf('outer_%03d',results.n));
if ~isfolder(outer_dir), mkdir(outer_dir); end
T = table(results.n,results.Nfan,results.prFAN_tip,results.prFAN_hub, ...
    results.W13,results.effFAN_tip,results.W22,results.effFAN_hub, ...
    'VariableNames',{'outer_iter','Nf_rpm','pr_b_target','pr_c_target', ...
    'w_b_0d','eff_b_0d','w_c_0d','eff_c_0d'});
writetable(T,fullfile(outer_dir,'outer_target.csv'));
fprintf('[SUCCESS] 2-D outer target written to %s\n',outer_dir);
end
