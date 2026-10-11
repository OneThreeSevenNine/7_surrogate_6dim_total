function out = rbf6_output_dir(parent,prefix)
name=[prefix datestr(now,'yyyymmdd_HHMMSS')]; out=fullfile(parent,name); suffix=0;
while exist(out,'dir'), suffix=suffix+1; out=fullfile(parent,sprintf('%s_%d',name,suffix)); end
[ok,msg]=mkdir(out); if ~ok, error('RBF6:Directory','%s',msg); end
end
