function [label,reason,limits] = rbf6_label(X,Y,rule)
% Apply the frozen version-3 speed-dependent flow envelope.
if nargin~=3 || isempty(rule), error('RBF6:LabelRule','X, Y, and a frozen label rule are required.'); end
validateattributes(Y,{'double'},{'2d','real','ncols',6});
n=size(Y,1); limits=nan(n,4);
if ~isfield(rule,'version') || rule.version~=3 || ~strcmp(rule.kind,'speed_flow_envelope')
    error('RBF6:LabelRule','Unsupported label rule version or kind.');
end
validateattributes(X,{'double'},{'2d','real','nrows',n,'ncols',3});
speed_ok=isfinite(X(:,1)) & X(:,1)>=rule.speed_nodes(1) & X(:,1)<=rule.speed_nodes(end);
if any(speed_ok)
    limits(speed_ok,1)=interp1(rule.speed_nodes,rule.wb_lower,X(speed_ok,1),'linear');
    limits(speed_ok,2)=interp1(rule.speed_nodes,rule.wb_upper,X(speed_ok,1),'linear');
    limits(speed_ok,3)=interp1(rule.speed_nodes,rule.wc_lower,X(speed_ok,1),'linear');
    limits(speed_ok,4)=interp1(rule.speed_nodes,rule.wc_upper,X(speed_ok,1),'linear');
end
finite=~any(~isfinite(Y),2);
bad=[~finite, ~speed_ok, ...
    ~(Y(:,1)>limits(:,1) & Y(:,1)<limits(:,2)), ...
    ~(Y(:,4)>limits(:,3) & Y(:,4)<limits(:,4)), ...
    ~(Y(:,2)>rule.efficiency_bounds(1) & Y(:,2)<rule.efficiency_bounds(2) & ...
      Y(:,5)>rule.efficiency_bounds(1) & Y(:,5)<rule.efficiency_bounds(2)), ...
    ~(Y(:,3)>rule.pressure_ratio_min & Y(:,6)>rule.pressure_ratio_min)];
names=["nonfinite","speed_outside_envelope","w_b_envelope","w_c_envelope", ...
    "efficiency_range","pressure_ratio_range"];
label=double(~any(bad,2)); reason=strings(n,1);
for i=1:n
    if label(i), reason(i)="usable";
    else, reason(i)=strjoin(names(bad(i,:)),";"); end
end
end
