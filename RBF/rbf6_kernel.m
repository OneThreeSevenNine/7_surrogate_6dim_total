function [K,G] = rbf6_kernel(X,C)
r2=zeros(size(X,1),size(C,1)); delta=zeros(size(X,1),size(C,1),3);
for j=1:3
    delta(:,:,j)=X(:,j)-C(:,j)'; r2=r2+delta(:,:,j).^2;
end
K=zeros(size(r2)); nz=r2>0; K(nz)=0.5*r2(nz).*log(r2(nz));
if nargout>1
    factor=zeros(size(r2)); factor(nz)=log(r2(nz))+1;
    G=delta.*factor;
end
end
