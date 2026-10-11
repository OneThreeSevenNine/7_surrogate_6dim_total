function rbf6_plots(d,t,raw,gate,CT,out,c)
f=figure('Visible','off','Position',[100 100 1000 700]);
scatter3(d.X(d.label==1,1),d.X(d.label==1,2),d.X(d.label==1,3),24,[0.2 0.5 0.8],'filled'); hold on;
scatter3(d.X(d.label==0,1),d.X(d.label==0,2),d.X(d.label==0,3),55,[0.85 0.2 0.1],'x');
scatter3(t.X(:,1),t.X(:,2),t.X(:,3),32,[0.2 0.7 0.3],'^');
xlabel('Nf (rpm)'); ylabel('ps_b (kPa)'); zlabel('ps_c (kPa)'); grid on;
legend('Training usable','Training unusable','Independent test','Location','best'); title('CFD input coverage and physical labels');
exportgraphics(f,fullfile(out,'sample_labels.png'),'Resolution',180); close(f);
f=figure('Visible','off','Position',[100 100 1250 450]);
for k=1:3
    subplot(1,3,k); counts=[CT.TN(k) CT.FP(k); CT.FN(k) CT.TP(k)];
    imagesc(counts); colorbar; xticks([1 2]); yticks([1 2]); xticklabels({'0','1'}); yticklabels({'0','1'});
    xlabel('Predicted'); ylabel('Actual'); title(strrep(CT.dataset{k},'_',' '));
    for i=1:2, for j=1:2, text(j,i,num2str(counts(i,j)),'HorizontalAlignment','center','Color','k','FontWeight','bold'); end,end
end
exportgraphics(f,fullfile(out,'confusion_matrices.png'),'Resolution',180); close(f);
mask=t.label==1;
f=figure('Visible','off','Position',[100 100 1200 750]);
for j=1:6
    subplot(2,3,j); scatter(t.Y(mask,j),raw(mask,j),28,'filled'); hold on;
    vals=[t.Y(mask,j);raw(mask,j)];
    if ~isempty(vals), lim=[min(vals) max(vals)]; plot(lim,lim,'k--'); end
    grid on; xlabel('CFD'); ylabel('RBF'); title(c.output_names{j},'Interpreter','none');
end
exportgraphics(f,fullfile(out,'test_prediction_comparison.png'),'Resolution',180); close(f);
f=figure('Visible','off','Position',[100 100 1200 750]);
for j=1:6
    subplot(2,3,j); err=100*(raw(mask,j)-t.Y(mask,j))./t.Y(mask,j);
    scatter(t.X(mask,1),err,28,'filled'); hold on; yline(0.1,'r--'); yline(-0.1,'r--');
    grid on; xlabel('Nf (rpm)'); ylabel('Relative error (%)'); title(c.output_names{j},'Interpreter','none');
end
exportgraphics(f,fullfile(out,'test_relative_errors.png'),'Resolution',180); close(f);
end
