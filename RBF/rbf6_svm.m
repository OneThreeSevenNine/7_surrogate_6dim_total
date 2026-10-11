function s = rbf6_svm(X,label,box,scale)
% Balanced weights and training-only range scaling.
s.xmin=min(X); s.span=max(X)-s.xmin;
if any(s.span<=0) || numel(unique(label))~=2, error('RBF6:SVM','Degenerate classifier data'); end
w=zeros(size(label)); n=numel(label);
for cls=0:1, mask=label==cls; w(mask)=n/(2*sum(mask)); end
s.classifier=fitcsvm((X-s.xmin)./s.span,label,'KernelFunction','gaussian', ...
    'KernelScale',scale,'BoxConstraint',box,'Weights',w,'Standardize',false,'ClassNames',[0;1]);
s.box=box; s.scale=scale;
end
