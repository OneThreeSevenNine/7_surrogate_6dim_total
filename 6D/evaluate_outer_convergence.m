function result = evaluate_outer_convergence(outer_iter,run_root,threshold)
%EVALUATE_OUTER_CONVERGENCE Compare bypass/core RBF and 0D flow/efficiency.
validateattributes(outer_iter,{'numeric'},{'scalar','integer','positive','finite'});
validateattributes(threshold,{'numeric'},{'scalar','real','finite','positive'});
if ~(ischar(run_root) || (isstring(run_root) && isscalar(run_root)))
    error('COUPLING:RunRoot','run_root must be a character vector or string scalar.');
end
outer_path=fullfile(char(run_root),sprintf('outer_%03d',outer_iter));
target=read_one_row(fullfile(outer_path,'outer_target.csv'), ...
    {'outer_iter','w_b_0d','eff_b_0d','w_c_0d','eff_c_0d'});
matched=read_one_row(fullfile(outer_path,'matched_result.csv'), ...
    {'outer_iter','w_b','eff_b','w_c','eff_c'});

if numeric_scalar(target,'outer_iter')~=outer_iter || ...
        numeric_scalar(matched,'outer_iter')~=outer_iter
    error('COUPLING:ResidualIteration','Residual inputs do not match outer iteration %d.',outer_iter);
end
t=[numeric_scalar(target,'w_b_0d') numeric_scalar(target,'eff_b_0d') ...
   numeric_scalar(target,'w_c_0d') numeric_scalar(target,'eff_c_0d')];
m=[numeric_scalar(matched,'w_b') numeric_scalar(matched,'eff_b') ...
   numeric_scalar(matched,'w_c') numeric_scalar(matched,'eff_c')];
if any(~isfinite([t m])) || any([t m]<=0)
    error('COUPLING:ResidualValues','Flow and efficiency values must be finite and positive.');
end

residuals=(m-t)./t;
maximum=max(abs(residuals));
converged=all(abs(residuals)<threshold);
T=table(outer_iter,residuals(1),residuals(2),residuals(3),residuals(4), ...
    maximum,threshold,double(converged),'VariableNames', ...
    {'outer_iter','e_W_tip','e_eff_tip','e_W_hub','e_eff_hub', ...
     'max_abs_relative','threshold','converged'});
write_table_atomic(T,fullfile(outer_path,'outer_residual.csv'));
if converged, status='CONVERGED'; else, status='NOT_CONVERGED'; end
write_text(fullfile(outer_path,'outer_status.txt'),[status newline]);

result.status=status;
result.outer_iter=outer_iter;
result.residuals=residuals;
result.max_abs_relative=maximum;
fprintf(['[OUTER] status=%s e_W_tip=%.6e e_eff_tip=%.6e ' ...
    'e_W_hub=%.6e e_eff_hub=%.6e max=%.6e threshold=%.6e\n'], ...
    status,residuals(1),residuals(2),residuals(3),residuals(4),maximum,threshold);
end

function T=read_one_row(path,required)
if exist(path,'file')~=2, error('COUPLING:ResidualFile','Missing required CSV: %s',path); end
T=readtable(path);
if height(T)~=1 || ~all(ismember(required,T.Properties.VariableNames))
    error('COUPLING:ResidualSchema', ...
        '%s must contain one row and all required columns.',path);
end
end

function value=numeric_scalar(T,name)
value=T.(name);
if ~(isnumeric(value) || islogical(value)) || ~isscalar(value) || ~isreal(value)
    error('COUPLING:ResidualSchema','Column %s must contain one real numeric scalar.',name);
end
value=double(value);
end

function write_table_atomic(T,path)
temporary=[path '.tmp.csv'];
writetable(T,temporary);
[ok,message]=movefile(temporary,path,'f');
if ~ok, error('COUPLING:ResidualWrite','Unable to publish %s: %s',path,message); end
end

function write_text(path,text_value)
fid=fopen(path,'w');
if fid<0, error('COUPLING:ResidualWrite','Unable to write %s.',path); end
cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
fprintf(fid,'%s',text_value);
end
