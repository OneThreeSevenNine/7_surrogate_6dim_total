function d = rbf6_apply_labels(d,rule)
if rule.version>=2 && any(d.X(:,1)<rule.speed_nodes(1) | d.X(:,1)>rule.speed_nodes(end))
    idx=find(d.X(:,1)<rule.speed_nodes(1) | d.X(:,1)>rule.speed_nodes(end),1);
    error('RBF6:SpeedRange','%s line %d: Nf %.10g rpm is outside the frozen %.10g..%.10g rpm label envelope', ...
        d.source_file,d.source_lines(idx),d.X(idx,1),rule.speed_nodes(1),rule.speed_nodes(end));
end
[d.label,d.reason,d.flow_limits]=rbf6_label(d.X,d.Y,rule);
d.label_rule=rule;
end
