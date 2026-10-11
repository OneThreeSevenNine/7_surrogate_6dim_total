function model_file = main_rbf6()
c=rbf6_config();
if exist('fitcsvm','file')~=2 || ~license('test','Statistics_Toolbox')
    error('RBF6:Toolbox','Statistics and Machine Learning Toolbox required for SVM');
end
d=rbf6_read_data(c.train_file,c,true);
rule=rbf6_build_label_rule(d.X,d.Y,c);
d=rbf6_apply_labels(d,rule);
t=rbf6_read_data(c.test_file,c,false,d.X);
t=rbf6_apply_labels(t,rule);
rbf6_write_cleaned(t,fullfile(c.base_dir,'rbf_6_test_cleaned.txt'));
rbf6_write_cleaned(d,fullfile(c.base_dir,'rbf_6_train_cleaned.txt'));
fprintf('Training: %d usable, %d unusable; independent test: %d points\n',sum(d.label==1),sum(d.label==0),size(t.X,1));
out=rbf6_output_dir(fullfile(c.base_dir,'results'),'run_');
fprintf('Selecting SVM / RBF parameters using training-only five-fold CV...\n');
[svm,rbf,cv,params]=rbf6_select(d,c,rule);
model=struct('version',3,'data_schema_version',c.data_schema_version, ...
    'svm',svm,'rbf',rbf,'config',c,'training_data',d,'cv',cv, ...
    'input_names',{c.input_names},'input_units',{c.input_units}, ...
    'output_names',{c.output_names},'output_units',{c.output_units}, ...
    'label_rule',rule,'label_rule_description',c.label_rule,'inlet_conditions',c.inlet_conditions, ...
    'training_sha256',d.sha256,'created_at',datestr(now,30));
model_file=fullfile(out,'rbf6_model.mat'); save(model_file,'model','-v7.3');
writetable(params,fullfile(out,'parameter_selection.csv'));
rbf6_evaluate(model,t,out);
if ~strcmp(d.sha256,rbf6_hash(c.train_file)) || ~strcmp(t.sha256,rbf6_hash(c.test_file))
    error('RBF6:SourceChanged','Raw source files changed during training');
end
fprintf('Saved: %s\nSelected box=%g scale=%g lambda=%g (rcond=%g)\n',model_file,svm.box,svm.scale,rbf.lambda,rbf.rcond);
end
