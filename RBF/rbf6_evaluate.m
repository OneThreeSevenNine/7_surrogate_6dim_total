function rbf6_evaluate(model,t,out)
c=model.config; d=model.training_data; cv=model.cv;
rule=model.label_rule;
[trainRaw,~,~]=rbf6_predict(model.rbf,d.X);
[~,~,trainGate]=surrogate6_predict(model,d.X);
[testRaw,~,testInfo]=rbf6_predict(model.rbf,t.X);
[testGated,~,testGate]=surrogate6_predict(model,t.X);
cvGate=cv.raw; cvGate(cv.label==0,:)=NaN;
names=[c.input_names c.output_names];
T=array2table(d.A,'VariableNames',names); T.stable_label=d.label; T.reason=d.reason; T.source_line=d.source_lines;
writetable(T,fullfile(out,'train_cleaned.csv'));
T=array2table(t.A,'VariableNames',names); T.stable_label=t.label; T.reason=t.reason; T.source_line=t.source_lines;
writetable(T,fullfile(out,'test_labeled.csv'));
testGate.physical_valid=testInfo.physical_valid;
prediction_table(t,testRaw,testGated,testGate,zeros(size(t.label)),out,'test_predictions.csv',c);
cvInfo=struct('stable_label',cv.label,'svm_score',cv.score, ...
    'in_training_range',cv.in_training_range,'in_training_hull',cv.in_training_hull, ...
    'physical_valid',logical(rbf6_label(d.X,cv.raw,rule)));
prediction_table(d,cv.raw,cvGate,cvInfo,cv.fold,out,'cv_predictions.csv',c);
write_flow_envelope(rule,out);
classRows=[class_metrics('training',d.label,trainGate.stable_label); ...
    class_metrics('cross_validation',d.label,cv.label); ...
    class_metrics('independent_test_all_131',t.label,testGate.stable_label)];
CT=cell2table(classRows,'VariableNames' ,{'dataset','count','TN','FP','FN','TP', ...
    'stable_recall','divergent_recall','balanced_accuracy','false_stable_rate', ...
    'actual_stable_gate_coverage','predicted_stable_fraction'});
writetable(CT,fullfile(out,'classification_metrics.csv'));
rows=[reg_metrics('training_raw',d,trainRaw,c); ...
    reg_metrics('cross_validation_raw',d,cv.raw,c); ...
    reg_metrics('independent_test_raw',t,testRaw,c); ...
    reg_metrics('independent_test_gated',t,testGated,c)];
RT=cell2table(rows,'VariableNames',{'dataset','output','count', ...
    'MAE','RMSE','mean_abs_relative_error','max_abs_relative_error', ...
    'mean_abs_relative_percent','max_abs_relative_percent'});
writetable(RT,fullfile(out,'regression_metrics.csv'));
f=fopen(fullfile(out,'report.txt'),'w','n','UTF-8'); guard=onCleanup(@()fclose(f));
fprintf(f,'Six-output surrogate training and validation\n');
fprintf(f,'Data schema version: %d (canonical nine columns; rpm, kPa, kPa)\n',model.data_schema_version);
fprintf(f,'Training: %d; usable: %d; unusable: %d\nTest: %d; usable: %d; unusable: %d\n', ...
    size(d.X,1),sum(d.label==1),sum(d.label==0),size(t.X,1),sum(t.label==1),sum(t.label==0));
fprintf(f,'Inputs: Nf [rpm], ps_b [kPa], ps_c [kPa]; b=bypass, c=core\n');
fprintf(f,'Label rule: %s\n',rule.description);
fprintf(f,'Label calibration: first %d training rows, %d trusted usable, flow-span margin %.6g%%.\n', ...
    rule.reference_rows,rule.reference_usable_count,100*rule.margin_fraction);
fprintf(f,'Flow envelope nodes [Nf wb_lower wb_upper wc_lower wc_upper]:\n');
for k=1:numel(rule.speed_nodes)
    fprintf(f,'%.1f %.9g %.9g %.9g %.9g\n',rule.speed_nodes(k),rule.wb_lower(k),rule.wb_upper(k),rule.wc_lower(k),rule.wc_upper(k));
end
fprintf(f,'SVM BoxConstraint=%g, KernelScale=%g; RBF lambda=%g, rcond=%.8g\n',model.svm.box,model.svm.scale,model.rbf.lambda,model.rbf.rcond);
fprintf(f,'Five-fold selection balanced accuracy=%.8g; six-output relative RMSE=%.8g (%.6g%%)\n', ...
    cv.selection_balanced_accuracy,cv.selection_relative_RMSE,100*cv.selection_relative_RMSE);
fprintf(f,'CV scores are parameter-selection estimates, not a nested or independent validation.\n');
fprintf(f,'Test speed range: %.1f..%.1f rpm; actual-stable gate coverage=%.6g\n',min(t.X(:,1)),max(t.X(:,1)),mean(testGate.stable_label(t.label==1)==1));
fprintf(f,'All 131 test points are evaluated together; no source or speed subgroups are scored.\n');
if ~any(t.label==0), fprintf(f,'No divergent test samples: divergent recall / false-stable rate / balanced accuracy are NaN.\n'); end
if all(t.X(:,1)>3800 & t.X(:,1)<3900), fprintf(f,'Independent test covers near-100%% speed only; no full-speed independent validation.\n'); end
if ~any(d.label==0 & d.X(:,1)>=3860 & d.X(:,1)<=4053)
    fprintf(f,'No label-0 training points at 3860..4053 rpm: divergence detection there is unverified.\n');
end
fprintf(f,'0.1%% plot reference is not a guarantee of CFD replacement or coupled-system accuracy.\n');
fprintf(f,'SVM scores are signed scores, not calibrated probabilities. Domain flags describe support, not guaranteed accuracy.\n');
fprintf(f,'Raw RBF test errors include all physically usable CFD samples, regardless of classifier rejection.\n');
fprintf(f,'Analytic derivative tests only verify implementation, not true CFD derivatives.\n');
fprintf(f,'Train SHA256: %s\nTest SHA256: %s\n',d.sha256,t.sha256);
fprintf(f,'\nIndependent test raw regression (all usable CFD points):\n');
for j=1:6
    mask=t.label==1; e=testRaw(mask,j)-t.Y(mask,j); rel=abs(e./t.Y(mask,j));
    fprintf(f,'%s: n=%d MAE=%.8g RMSE=%.8g MARE=%.8g (%.6g%%) max=%.8g (%.6g%%)\n', ...
        c.output_names{j},sum(mask),mean(abs(e)),sqrt(mean(e.^2)),mean(rel),100*mean(rel),max(rel),100*max(rel));
end
fprintf(f,'\nIndependent classification over all 131 points:\n');
k=3;
fprintf(f,'%s n=%d TN=%d FP=%d FN=%d TP=%d stable_recall=%.6g divergent_recall=%.6g balanced_accuracy=%.6g false_stable_rate=%.6g stable_gate_coverage=%.6g\n', ...
    CT.dataset{k},CT.count(k),CT.TN(k),CT.FP(k),CT.FN(k),CT.TP(k), ...
    CT.stable_recall(k),CT.divergent_recall(k),CT.balanced_accuracy(k),CT.false_stable_rate(k),CT.actual_stable_gate_coverage(k));
fprintf(f,'\nIndependent raw and classifier-gated regression over the complete test set:\n');
for k=1:height(RT)
    if startsWith(RT.dataset{k},'independent_test')
        fprintf(f,'%s output=%s n=%d MAE=%.8g RMSE=%.8g MARE=%.8g (%.6g%%) max=%.8g (%.6g%%)\n', ...
            RT.dataset{k},RT.output{k},RT.count(k),RT.MAE(k),RT.RMSE(k), ...
            RT.mean_abs_relative_error(k),RT.mean_abs_relative_percent(k), ...
            RT.max_abs_relative_error(k),RT.max_abs_relative_percent(k));
    end
end
fprintf(f,'Model remains frozen; current test data only used for evaluation.\n');
clear guard;
rbf6_plots(d,t,testRaw,testGate,CT,out,c);
disp(CT); disp(RT(strcmp(RT.dataset,'independent_test_raw'),:));
end

function write_flow_envelope(rule,out)
E=table(rule.speed_nodes(:),rule.wb_reference_min(:),rule.wb_reference_max(:), ...
    rule.wb_lower(:),rule.wb_upper(:),rule.wc_reference_min(:),rule.wc_reference_max(:), ...
    rule.wc_lower(:),rule.wc_upper(:),'VariableNames', ...
    {'Nf_rpm','wb_reference_min','wb_reference_max','wb_lower','wb_upper', ...
    'wc_reference_min','wc_reference_max','wc_lower','wc_upper'});
writetable(E,fullfile(out,'label_rule_flow_envelope.csv'));
end

function prediction_table(d,raw,gated,info,fold,out,name,c)
T=array2table(d.X,'VariableNames',c.input_names); T.source_line=d.source_lines;
T.actual_stable_label=d.label; T.predicted_stable_label=info.stable_label;
T.svm_score=info.svm_score; T.cv_fold=fold;
T.in_training_range=info.in_training_range; T.in_training_hull=info.in_training_hull;
T.is_extrapolation=~info.in_training_hull; T.raw_physical_valid=info.physical_valid;
T.is_usable=info.stable_label==1 & info.physical_valid;
for j=1:6
    nm=c.output_names{j}; T.([nm '_CFD'])=d.Y(:,j);
    T.([nm '_raw'])=raw(:,j); T.([nm '_gated'])=gated(:,j);
    err=raw(:,j)-d.Y(:,j); err(d.label==0)=NaN;
    T.([nm '_error'])=err;
    T.([nm '_relative_error'])=err./d.Y(:,j);
    T.([nm '_relative_percent'])=100*err./d.Y(:,j);
end
writetable(T,fullfile(out,name));
end

function rows=class_metrics(name,actual,pred)
tn=sum(actual==0 & pred==0); fp=sum(actual==0 & pred==1);
fn=sum(actual==1 & pred==0); tp=sum(actual==1 & pred==1);
sr=ratio(tp,tp+fn); dr=ratio(tn,tn+fp);
rows={name,numel(actual),tn,fp,fn,tp,sr,dr,(sr+dr)/2,ratio(fp,fp+tn),sr,mean(pred==1)};
end

function val=ratio(a,b)
if b==0, val=NaN; else, val=a/b; end
end

function rows=reg_metrics(name,d,pred,c)
mask=d.label==1 & all(isfinite(pred),2); rows=cell(6,9);
for j=1:6
    e=pred(mask,j)-d.Y(mask,j); rel=abs(e./d.Y(mask,j));
    if isempty(e), mae=NaN; rmse=NaN; avg=NaN; mx=NaN;
    else, mae=mean(abs(e)); rmse=sqrt(mean(e.^2)); avg=mean(rel); mx=max(rel); end
    rows(j,:)={name,c.output_names{j},sum(mask),mae,rmse,avg,mx,100*avg,100*mx};
end
end
