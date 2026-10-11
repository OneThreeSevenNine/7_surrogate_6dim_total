function rbf6_write_cleaned(d,path)
% No reason column; all CFD rows retained, including unusable/NaN outputs.
f=fopen(path,'w'); if f<0, error('RBF6:File','Cannot write %s',path); end
guard=onCleanup(@()fclose(f));
fprintf(f,'Nf ps_b ps_c w_b eff_b pr_b w_c eff_c pr_c stable_label\n');
fprintf(f,'%.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %d\n',[d.A d.label]');
end
