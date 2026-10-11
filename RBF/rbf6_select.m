function [svm,rbf,cv,params] = rbf6_select(d,c,rule)
% Stratified folds are shared by classifier and regression; test data absent.
rng(c.seed,'twister'); n=size(d.X,1); fold=zeros(n,1);
for cls=0:1
    ids=find(d.label==cls); if numel(ids)<c.folds, error('RBF6:Folds','Insufficient class %d for %d folds',cls,c.folds); end
    ids=ids(randperm(numel(ids))); fold(ids)=mod((0:numel(ids)-1)',c.folds)+1;
end
cv.fold=fold; cv.raw=nan(n,6); cv.label=nan(n,1); cv.score=nan(n,1);
cv.in_training_range=false(n,1); cv.in_training_hull=false(n,1);
rows={}; best=-Inf; bestfalse=Inf; bestbox=Inf; bestscale=Inf;
for box=c.box_candidates
    for scale=c.scale_candidates
        pred=nan(n,1); score=nan(n,1); failure="";
        try
            for f=1:c.folds
                tr=fold~=f; va=fold==f; s=rbf6_svm(d.X(tr,:),d.label(tr),box,scale);
                [pred(va),sc]=predict(s.classifier,(d.X(va,:)-s.xmin)./s.span);
                score(va)=sc(:,s.classifier.ClassNames==1);
            end
            sr=mean(pred(d.label==1)==1); dr=mean(pred(d.label==0)==0);
            bal=(sr+dr)/2; fs=1-dr;
        catch err
            failure=string(err.message); bal=NaN; fs=NaN;
        end
        rows(end+1,:)={'svm',box,scale,NaN,bal,fs,NaN,strlength(failure)==0,char(failure)}; %#ok<AGROW>
        if isfinite(bal) && (bal>best+1e-12 || (abs(bal-best)<=1e-12 && ...
                (fs<bestfalse-1e-12 || (abs(fs-bestfalse)<=1e-12 && ...
                (box<bestbox || (box==bestbox && scale<bestscale))))))
            best=bal; bestfalse=fs; bestbox=box; bestscale=scale;
            cv.label=pred; cv.score=score;
        end
    end
end
if ~isfinite(best), error('RBF6:SVMSelection','All SVM candidates failed'); end
svm=rbf6_svm(d.X,d.label,bestbox,bestscale);
besterr=Inf; bestlambda=Inf;
for lambda=c.lambda_candidates
    pred=nan(n,6); range=false(n,1); hull=false(n,1); failure="";
    try
        for f=1:c.folds
            tr=fold~=f & d.label==1; va=fold==f & d.label==1;
            r=rbf6_train(d.X(tr,:),d.Y(tr,:),lambda,c,rule);
            [pred(va,:),~,info]=rbf6_predict(r,d.X(va,:));
            range(va)=info.in_training_range; hull(va)=info.in_training_hull;
        end
        rel=(pred(d.label==1,:)-d.Y(d.label==1,:))./d.Y(d.label==1,:);
        score=sqrt(mean(rel(:).^2));
    catch err
        failure=string(err.message); score=NaN;
    end
    rows(end+1,:)={'rbf',NaN,NaN,lambda,NaN,NaN,score,strlength(failure)==0,char(failure)}; %#ok<AGROW>
    if isfinite(score) && (score<besterr-1e-12 || (abs(score-besterr)<=1e-12 && lambda<bestlambda))
        besterr=score; bestlambda=lambda; cv.raw=pred;
        cv.in_training_range=range; cv.in_training_hull=hull;
    end
end
if ~isfinite(besterr), error('RBF6:RBFSelection','All RBF candidates failed'); end
rbf=rbf6_train(d.X(d.label==1,:),d.Y(d.label==1,:),bestlambda,c,rule);
params=cell2table(rows,'VariableNames',{'model_type','BoxConstraint','KernelScale','lambda', ...
    'balanced_accuracy','false_stable_rate','relative_RMSE','success','failure_reason'});
cv.selection_balanced_accuracy=best; cv.selection_relative_RMSE=besterr;
end
