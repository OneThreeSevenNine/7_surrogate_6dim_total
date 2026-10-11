function [Y,J,info] = rbf6_predict(r,X)
validateattributes(X,{'double'},{'real','finite','2d','ncols',3});
if any(X(:)<=0), error('RBF6:Query','Physical inputs must be positive'); end
Z=(X-r.xmin)./r.span; [K,G]=rbf6_kernel(Z,r.centers);
Y=K*r.weights+[ones(size(X,1),1) Z]*r.tail;
if any(~isfinite(Y(:))), error('RBF6:Prediction','Nonfinite RBF output'); end
J=zeros(size(X,1),6,3);
for j=1:3, J(:,:,j)=(G(:,:,j)*r.weights+r.tail(j+1,:))/r.span(j); end
info.outside_dimensions=Z < -r.domain_tolerance | Z>1+r.domain_tolerance;
info.in_training_range=~any(info.outside_dimensions,2);
info.in_training_hull=~any([Z ones(size(Z,1),1)]*r.planes'>r.domain_tolerance,2);
info.is_extrapolation=~info.in_training_hull;
if ~isfield(r,'label_rule'), error('RBF6:ModelVersion','RBF model is missing the frozen version-3 label rule.'); end
info.physical_valid=logical(rbf6_label(X,Y,r.label_rule));
end
