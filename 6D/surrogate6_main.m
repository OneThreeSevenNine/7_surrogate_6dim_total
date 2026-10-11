function result = surrogate6_main(outer_iter,run_root)
%SURROGATE6_MAIN Run one pure SVM/RBF outer-coupling prediction.
validateattributes(outer_iter,{'numeric'},{'scalar','integer','positive','finite'});
if ~(ischar(run_root) || (isstring(run_root) && isscalar(run_root)))
    error('SURROGATE6:RunRoot','run_root must be a character vector or string scalar.');
end
run_root=char(run_root);
outer_path=fullfile(run_root,sprintf('outer_%03d',outer_iter));
if ~isfolder(outer_path), mkdir(outer_path); end
status_path=fullfile(outer_path,'surrogate_status.txt');
diagnostic_path=fullfile(outer_path,'surrogate_diagnostic.txt');
write_text(status_path,['RUNNING' newline]);

try
    config=surrogate6_config();
    addpath(config.rbf_dir);
    validate_model_environment(config);
    loaded=load(config.model_file,'model');
    model=loaded.model;
    validate_model_schema(model,config);
    target=read_target(fullfile(outer_path,'outer_target.csv'),outer_iter);
    warm_pressure=read_warm_pressure(run_root,outer_iter);
    [pressure,diagnostic]=surrogate6_solve_root(model,target.Nf_rpm, ...
        [target.pr_b_target target.pr_c_target],warm_pressure,config);

    y=diagnostic.predicted_outputs;
    matched=table(outer_iter,diagnostic.selected_iterations,target.Nf_rpm, ...
        pressure(1),pressure(2),1000*pressure(1),1000*pressure(2), ...
        target.pr_b_target,target.pr_c_target, ...
        y(1),y(2),y(3),y(4),y(5),y(6), ...
        diagnostic.relative_residual(1),diagnostic.relative_residual(2), ...
        diagnostic.max_relative_residual,diagnostic.svm_label, ...
        diagnostic.svm_score,diagnostic.in_training_range, ...
        diagnostic.in_training_hull,diagnostic.rbf_physical_valid, ...
        {diagnostic.solution_mode},'VariableNames', ...
        {'outer_iter','root_iterations','Nf_rpm', ...
         'ps_b_kPa','ps_c_kPa','ps_b_Pa','ps_c_Pa', ...
         'pr_b_target','pr_c_target','w_b','eff_b','pr_b','w_c','eff_c','pr_c', ...
         'rel_pr_b','rel_pr_c','max_abs_relative','svm_label','svm_score', ...
         'in_training_range','in_training_hull','rbf_physical_valid','solution_mode'});
    write_table_atomic(matched,fullfile(outer_path,'matched_result.csv'));

    model_hash=rbf6_hash(config.model_file);
    write_diagnostic(diagnostic_path,outer_iter,target,pressure,diagnostic,model_hash,'CONVERGED','');
    write_text(status_path,['CONVERGED' newline]);

    result.status='CONVERGED';
    result.outer_iter=outer_iter;
    result.pressure_kPa=pressure;
    result.max_relative_residual=diagnostic.max_relative_residual;
    result.solution_mode=diagnostic.solution_mode;
    fprintf(['[SURROGATE6] outer=%d mode=%s ps_b=%.8g kPa ps_c=%.8g kPa ' ...
        'max pressure-ratio residual=%.6e\n'],outer_iter,diagnostic.solution_mode, ...
        pressure(1),pressure(2),diagnostic.max_relative_residual);
catch ME
    write_text(status_path,['FAILED' newline]);
    write_failure_diagnostic(diagnostic_path,outer_iter,ME);
    rethrow(ME);
end
end

function validate_model_environment(config)
if exist(config.model_file,'file')~=2
    error('SURROGATE6:MissingModel','Frozen model is missing: %s',config.model_file);
end
if ~license('test','Statistics_Toolbox')
    error('SURROGATE6:Toolbox','Statistics and Machine Learning Toolbox is required.');
end
end

function validate_model_schema(model,config)
required={'version','data_schema_version','input_names','output_names','svm','rbf'};
if ~isstruct(model) || ~all(isfield(model,required))
    error('SURROGATE6:ModelSchema','The frozen model is missing required fields.');
end
if model.version~=3 || model.data_schema_version~=2
    error('SURROGATE6:ModelVersion', ...
        'Expected model version 3 and data schema version 2.');
end
if ~isequal(model.input_names,config.input_order) || ...
        ~isequal(model.output_names,config.output_order)
    error('SURROGATE6:ModelSchema','Frozen model input/output order is incompatible.');
end
end

function target=read_target(path,outer_iter)
required={'outer_iter','Nf_rpm','pr_b_target','pr_c_target', ...
    'w_b_0d','eff_b_0d','w_c_0d','eff_c_0d'};
T=read_one_row(path,required,'SURROGATE6:TargetSchema');
values=zeros(1,numel(required));
for i=1:numel(required), values(i)=numeric_scalar(T,required{i}); end
if values(1)~=outer_iter
    error('SURROGATE6:TargetIteration', ...
        'outer_target.csv contains outer_iter=%g; expected %d.',values(1),outer_iter);
end
if any(~isfinite(values)) || any(values<=0)
    error('SURROGATE6:TargetValues','All outer target values must be finite and positive.');
end
target=table2struct(T);
end

function pressure=read_warm_pressure(run_root,outer_iter)
pressure=[];
if outer_iter<=1, return; end
path=fullfile(run_root,sprintf('outer_%03d',outer_iter-1),'matched_result.csv');
T=read_one_row(path,{'outer_iter','ps_b_kPa','ps_c_kPa'},'SURROGATE6:WarmStart');
if numeric_scalar(T,'outer_iter')~=outer_iter-1
    error('SURROGATE6:WarmStart','Previous matched result has the wrong outer iteration.');
end
pressure=[numeric_scalar(T,'ps_b_kPa') numeric_scalar(T,'ps_c_kPa')];
if any(~isfinite(pressure)) || any(pressure<=0)
    error('SURROGATE6:WarmStart','Previous matched pressures must be finite and positive.');
end
end

function T=read_one_row(path,required,error_id)
if exist(path,'file')~=2, error(error_id,'Required CSV is missing: %s',path); end
T=readtable(path);
if height(T)~=1 || ~all(ismember(required,T.Properties.VariableNames))
    error(error_id,'%s must contain one row and all required columns.',path);
end
end

function value=numeric_scalar(T,name)
value=T.(name);
if ~(isnumeric(value) || islogical(value)) || ~isscalar(value) || ~isreal(value)
    error('SURROGATE6:NumericField','Column %s must contain one real numeric scalar.',name);
end
value=double(value);
end

function write_table_atomic(T,path)
temporary=[path '.tmp.csv'];
writetable(T,temporary);
[ok,message]=movefile(temporary,path,'f');
if ~ok, error('SURROGATE6:FileWrite','Unable to publish %s: %s',path,message); end
end

function write_diagnostic(path,outer_iter,target,pressure,d,model_hash,status,message)
fid=fopen(path,'w');
if fid<0, error('SURROGATE6:FileWrite','Unable to write %s.',path); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'status=%s\nmessage=%s\nouter_iter=%d\nmodel_sha256=%s\n', ...
    status,message,outer_iter,model_hash);
fprintf(fid,'Nf_rpm=%.12g\npr_b_target=%.12g\npr_c_target=%.12g\n', ...
    target.Nf_rpm,target.pr_b_target,target.pr_c_target);
fprintf(fid,'ps_b_kPa=%.12g\nps_c_kPa=%.12g\n',pressure(1),pressure(2));
fprintf(fid,['solution_mode=%s\nroot_iterations=%d\nmax_abs_relative=%.12g\n' ...
    'rel_pr_b=%.12g\nrel_pr_c=%.12g\nsvm_label=%d\nsvm_score=%.12g\n' ...
    'in_training_range=%d\nin_training_hull=%d\nrbf_physical_valid=%d\n' ...
    'seed_count=%d\nadmissible_seed_count=%d\nconverged_root_count=%d\n'], ...
    d.solution_mode,d.selected_iterations,d.max_relative_residual, ...
    d.relative_residual(1),d.relative_residual(2),d.svm_label,d.svm_score, ...
    d.in_training_range,d.in_training_hull,d.rbf_physical_valid, ...
    d.seed_count,d.admissible_seed_count,d.converged_root_count);
fprintf(fid,'pressure_jacobian=[%.12g %.12g; %.12g %.12g]\n', ...
    d.pressure_jacobian(1,1),d.pressure_jacobian(1,2), ...
    d.pressure_jacobian(2,1),d.pressure_jacobian(2,2));
end

function write_failure_diagnostic(path,outer_iter,ME)
fid=fopen(path,'w');
if fid<0, return; end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'status=FAILED\nouter_iter=%d\nidentifier=%s\nmessage=%s\n', ...
    outer_iter,ME.identifier,strrep(ME.message,newline,' '));
end

function write_text(path,text_value)
fid=fopen(path,'w');
if fid<0, error('SURROGATE6:FileWrite','Unable to write %s.',path); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',text_value);
end
