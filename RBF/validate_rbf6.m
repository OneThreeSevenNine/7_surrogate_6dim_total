function out = validate_rbf6(model_file)
if nargin~=1, error('RBF6:Usage','Pass the saved rbf6_model.mat path'); end
before=rbf6_hash(model_file); loaded=load(model_file,'model'); model=loaded.model;
if ~isfield(model,'version') || model.version~=3 || ~isfield(model,'data_schema_version') || model.data_schema_version~=2
    error('RBF6:ModelVersion','Only version-3 models trained from the canonical nine-column schema are supported.');
end
c=rbf6_config(); train_before=rbf6_hash(c.train_file);
rule=model.label_rule;
t=rbf6_read_data(c.test_file,c,false,model.training_data.X);
t=rbf6_apply_labels(t,rule);
rbf6_write_cleaned(t,fullfile(c.base_dir,'rbf_6_test_cleaned.txt'));
out=rbf6_output_dir(fileparts(model_file),'validation_');
rbf6_evaluate(model,t,out);
if ~strcmp(before,rbf6_hash(model_file)), error('RBF6:ModelChanged','Saved model changed'); end
if ~strcmp(t.sha256,rbf6_hash(c.test_file)), error('RBF6:SourceChanged','Test file changed'); end
if ~strcmp(train_before,rbf6_hash(c.train_file)), error('RBF6:SourceChanged','Training file changed'); end
fprintf('Independent validation saved: %s\n',out);
end
