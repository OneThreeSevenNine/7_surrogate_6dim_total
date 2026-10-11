function [Ypred,J,info] = surrogate6_predict(model,Xquery)
% Inputs [rpm kPa kPa]; outputs [w_b eff_b pr_b w_c eff_c pr_c].
validateattributes(Xquery,{'double'},{'real','finite','2d','ncols',3});
if any(Xquery(:)<=0), error('RBF6:Query','Inputs must be positive'); end
[label,score]=predict(model.svm.classifier,(Xquery-model.svm.xmin)./model.svm.span);
Z=(Xquery-model.rbf.xmin)./model.rbf.span;
tol=model.rbf.domain_tolerance;
info.outside_dimensions=Z < -tol | Z>1+tol;
info.in_training_range=~any(info.outside_dimensions,2);
info.in_training_hull=~any([Z ones(size(Z,1),1)]*model.rbf.planes'>tol,2);
info.is_extrapolation=~info.in_training_hull;
info.physical_valid=false(size(label));
Ypred=nan(size(Xquery,1),6); J=nan(size(Xquery,1),6,3);
accepted=label==1;
if any(accepted)
    [Ypred(accepted,:),J(accepted,:,:),acceptedInfo]=rbf6_predict(model.rbf,Xquery(accepted,:));
    info.physical_valid(accepted)=acceptedInfo.physical_valid;
end
info.stable_label=label;
column=find(model.svm.classifier.ClassNames==1);
info.svm_score=score(:,column); info.score_is_probability=false;
info.is_usable=label==1 & info.physical_valid;
end
