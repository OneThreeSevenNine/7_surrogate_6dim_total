function r = rbf6_train(X,Y,lambda,c,rule)
if nargin<5 || isempty(rule), error('RBF6:LabelRule','A frozen version-3 label rule is required.'); end
validateattributes(X,{'double'},{'real','finite','2d','ncols',3});
validateattributes(Y,{'double'},{'real','finite','2d','ncols',6});
if size(X,1)~=size(Y,1) || size(unique(X,'rows'),1)~=size(X,1), error('RBF6:Shape','Invalid training rows'); end
if any(rbf6_label(X,Y,rule)==0), error('RBF6:Label','RBF training includes an unusable output'); end
xmin=min(X); span=max(X)-xmin;
if any(span<=0), error('RBF6:Rank','Degenerate input span'); end
Z=(X-xmin)./span; n=size(X,1); P=[ones(n,1) Z];
if rank(P)<4, error('RBF6:Rank','Affine tail rank deficient'); end
K=rbf6_kernel(Z,Z); B=[K+lambda*eye(n),P;P',zeros(4)];
rc=rcond(B);
if ~isfinite(rc) || rc<c.min_rcond || rank(B)<n+4
    error('RBF6:Condition','Invalid augmented matrix: rcond %.3g',rc);
end
coef=B\[Y;zeros(4,6)];
if any(~isfinite(coef(:))), error('RBF6:Coefficients','Nonfinite coefficients'); end
r=struct('X',X,'Y',Y,'centers',Z,'xmin',xmin,'span',span,'xmax',max(X), ...
    'weights',coef(1:n,:),'tail',coef(n+1:end,:),'lambda',lambda,'rcond',rc, ...
    'kernel','thin_plate_spline','domain_tolerance',c.domain_tolerance,'label_rule',rule);
faces=convhulln(Z); center=mean(Z); planes=zeros(size(faces,1),4);
for i=1:size(faces,1)
    p=Z(faces(i,1),:); normal=cross(Z(faces(i,2),:)-p,Z(faces(i,3),:)-p);
    normal=normal/norm(normal); if dot(normal,center-p)>0, normal=-normal; end
    planes(i,:)=[normal,-dot(normal,p)];
end
r.planes=planes;
end
