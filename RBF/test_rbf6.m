function test_rbf6(model_file,reselect)
% Default acceptance checks do not refit the frozen models.
if nargin<2, reselect=false; end
c=rbf6_config(); beforeTrain=rbf6_hash(c.train_file); beforeTest=rbf6_hash(c.test_file);
d=rbf6_read_data(c.train_file,c,true); rule=rbf6_build_label_rule(d.X,d.Y,c); d=rbf6_apply_labels(d,rule);
t=rbf6_read_data(c.test_file,c,false,d.X); t=rbf6_apply_labels(t,rule);
assert(size(d.X,1)==315 && sum(d.label)==275 && sum(d.label==0)==40);
assert(size(t.X,1)==131 && sum(t.label)==113 && sum(t.label==0)==18);
assert(sum(d.label(1:165))==163 && sum(d.label(1:165)==0)==2);
assert(rule.version==3 && rule.reference_rows==165 && abs(rule.margin_fraction-0.05)<eps);
expected=[242.4266274 294.7360406 27.3842266 32.2253794; ...
    264.2032169 317.6435951 28.4672003 33.2285657; ...
    288.07373165 327.32112335 29.42409665 34.23623035; ...
    305.44664005 343.96186295 32.3455161 35.2394819; ...
    333.05761965 356.27911135 31.3839732 36.4649348; ...
    355.2713225 361.2283395 34.76675025 37.32259475];
actual=[rule.wb_lower' rule.wb_upper' rule.wc_lower' rule.wc_upper'];
assert(max(abs(actual-expected),[],'all')<1e-8);
target=find(abs(t.X(:,1)-3106)<1e-12 & abs(t.X(:,2)-114.043)<1e-12 & abs(t.X(:,3)-117.270)<1e-12);
assert(numel(target)==1 && t.label(target)==0);
tsrc=readmatrix(c.test_file,'FileType','text','NumHeaderLines',1);
assert(isequaln(t.A,tsrc(:,1:9)));
wrong=c; wrong.test_rows=130;
expect_error(@()rbf6_read_data(c.test_file,wrong,false),'RBF6:Layout');
src=readmatrix(c.train_file,'FileType','text','NumHeaderLines',1);
assert(isequaln(d.A,src(:,1:9)));
Xgood=[3088 105 105]; good=[mean(rule.wb_lower(1:2)) .75 1.3 mean(rule.wc_lower(1:2)) .8 1.4];
assert(rbf6_label(Xgood,good,rule)==1);
for val=[rule.wb_lower(1) rule.wb_upper(1)], y=good; y(1)=val; assert(rbf6_label(Xgood,y,rule)==0); end
for val=[rule.wc_lower(1) rule.wc_upper(1)], y=good; y(4)=val; assert(rbf6_label(Xgood,y,rule)==0); end
edges={2,[0.5 1];5,[0.5 1];3,1;6,1};
for k=1:size(edges,1), for val=edges{k,2}, y=good; y(edges{k,1})=val; assert(rbf6_label(Xgood,y,rule)==0); end, end
assert(rbf6_label([3087.9 105 105],good,rule)==0 && rbf6_label([4053.1 105 105],good,rule)==0);
for j=1:6
    y=good; y(j)=NaN; assert(rbf6_label(Xgood,y,rule)==0);
    y=good; y(j)=Inf; assert(rbf6_label(Xgood,y,rule)==0);
end
saved=load(model_file,'model'); model=saved.model;
assert(model.version==3 && model.data_schema_version==2 && isequaln(model.label_rule,rule));
assert(isequal(model.rbf.X,d.X(d.label==1,:)));
assert(isequal(model.rbf.Y,d.Y(d.label==1,:)));
rng(c.seed,'twister'); fold=zeros(size(d.label));
for cls=0:1, ids=find(d.label==cls); ids=ids(randperm(numel(ids))); fold(ids)=mod((0:numel(ids)-1)',c.folds)+1; end
assert(isequal(fold,model.cv.fold));
if reselect
[s2,r2,cv2,params2]=rbf6_select(d,c,rule);
assert(s2.box==model.svm.box && s2.scale==model.svm.scale && r2.lambda==model.rbf.lambda);
assert(isequal(cv2.fold,model.cv.fold) && isequal(cv2.label,model.cv.label));
assert(max(abs(cv2.raw(d.label==1,:)-model.cv.raw(d.label==1,:)),[],'all')<1e-10);
assert(all(params2.success));
end
expect_error(@()rbf6_read_data(c.test_file,c,false,t.X),'RBF6:Overlap');
check_fixture([d.A(1,:);d.A(1,:)],c,'RBF6:Duplicate');
bad=d.A(1,:); bad(1)=NaN; check_fixture(bad,c,'RBF6:Input');
bad=d.A(1,:); bad(2:3)=bad(2:3)*1000; check_fixture(bad,c,'RBF6:Units');
check_fixture(d.A(1,1:8),c,'RBF6:Columns');
[K,G]=rbf6_kernel(model.rbf.centers(1,:),model.rbf.centers(1,:));
assert(K==0 && all(G(:)==0));
Q=[model.rbf.X(1:3,:);mean(model.rbf.X)]; originalQ=Q;
[Y,J]=rbf6_predict(model.rbf,Q);
h=1e-6;
for j=1:3
    plus=Q; minus=Q; plus(:,j)=plus(:,j)+h*model.rbf.span(j); minus(:,j)=minus(:,j)-h*model.rbf.span(j);
    fd=(rbf6_predict(model.rbf,plus)-rbf6_predict(model.rbf,minus))/(2*h*model.rbf.span(j));
    exact=J(:,:,j); assert(max(abs(fd(:)-exact(:))./(1+abs(exact(:))))<5e-5);
end
assert(isequal(Q,originalQ));
[~,~,info]=rbf6_predict(model.rbf,model.rbf.xmax+[1 1 1]);
assert(info.is_extrapolation && ~info.in_training_range);
[gate,Jgate,gi]=surrogate6_predict(model,d.X);
assert(all(all(isnan(gate(gi.stable_label==0,:)))));
assert(all(all(all(isnan(Jgate(gi.stable_label==0,:,:))))));
tmp=[tempname '.mat']; save(tmp,'model'); again=load(tmp,'model');
[a,ja,ia]=surrogate6_predict(model,t.X); [b,jb,ib]=surrogate6_predict(again.model,t.X);
assert(isequaln(a,b) && isequaln(ja,jb) && isequaln(ia,ib)); delete(tmp);
before=rbf6_hash(model_file); validation_dir=validate_rbf6(model_file); assert(strcmp(before,rbf6_hash(model_file)));
clean=readmatrix(fullfile(c.base_dir,'rbf_6_test_cleaned.txt'),'FileType','text','NumHeaderLines',1);
assert(size(clean,1)==131 && size(clean,2)==10);
assert(isequaln(clean(:,1:3),t.X) && isequaln(clean(:,10),t.label));
table=readtable(fullfile(validation_dir,'classification_metrics.csv'));
assert(height(table)==3 && isequal(table.dataset,{'training';'cross_validation';'independent_test_all_131'}));
rt=readtable(fullfile(validation_dir,'regression_metrics.csv'));
assert(~ismember('speed_group',rt.Properties.VariableNames));
assert(sum(rt.count(strcmp(rt.dataset,'independent_test_raw')))==113*6);
assert(isfile(fullfile(validation_dir,'label_rule_flow_envelope.csv')));
assert(strcmp(beforeTrain,rbf6_hash(c.train_file)) && strcmp(beforeTest,rbf6_hash(c.test_file)));
assert(all(isfinite(Y(:))));
fprintf('PASS: cleaning, labels, folds, stable-only training, save/load, derivatives, domain flags, gating, independent validation, source hashes.\n');
end

function expect_error(fn,id)
thrown=false;
try, fn(); catch err, assert(strcmp(err.identifier,id),err.message); thrown=true; end
assert(thrown,['Expected error: ' id]);
end

function check_fixture(A,c,id)
c.test_rows=size(A,1);
p=[tempname '.txt']; guard=onCleanup(@()delete(p));
f=fopen(p,'w'); fprintf(f,'Nf ps_b ps_c w_b eff_b pr_b w_c eff_c pr_c\n');
for i=1:size(A,1), fprintf(f,'%.17g ',A(i,:)); fprintf(f,'\n'); end
fclose(f); expect_error(@()rbf6_read_data(p,c,false),id);
end
