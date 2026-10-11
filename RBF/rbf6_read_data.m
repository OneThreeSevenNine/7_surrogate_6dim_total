function d = rbf6_read_data(path,c,is_train,trainX,rule)
% Read the canonical nine-column rpm/kPa/kPa data layout without conversion.
if nargin<4, trainX=[]; end
if nargin<5, rule=[]; end
lines=splitlines(string(fileread(path))); expected=[c.input_names c.output_names];
head=regexp(char(strtrim(lines(1))),'\s+','split');
if ~isequal(head,expected), error('RBF6:Header','Incorrect column order in %s',path); end
A=zeros(0,9); source_lines=zeros(0,1);
for j=2:numel(lines)
    s=strtrim(lines(j)); if strlength(s)==0, continue; end
    tok=string(regexp(char(s),'\s+','split'))'; if numel(tok)~=9
        error('RBF6:Columns','%s line %d: expected 9 columns, got %d',path,j,numel(tok));
    end
    v=str2double(tok)';
    invalid=isnan(v) & ~strcmpi(tok','NaN');
    if any(invalid), error('RBF6:Numeric','%s line %d contains invalid numeric text',path,j); end
    A(end+1,:)=v; source_lines(end+1,1)=j; %#ok<AGROW>
end
if isempty(A), error('RBF6:Empty','Empty data file %s',path); end
if is_train, expected_rows=c.train_rows; else, expected_rows=c.test_rows; end
if size(A,1)~=expected_rows
    error('RBF6:Layout','Expected %d rows in %s, got %d.',expected_rows,path,size(A,1));
end
X=A(:,1:3);
bad=any(~isfinite(X) | X<=0,2);
if any(bad), idx=find(bad,1); error('RBF6:Input','%s line %d: input must be finite and positive',path,source_lines(idx)); end
if any(any(X(:,2:3)<50 | X(:,2:3)>200)), error('RBF6:Units','%s: expected pressure in kPa (50..200)',path); end
[~,first]=unique(X,'rows','stable'); duplicate=setdiff((1:size(X,1))',first);
if ~isempty(duplicate), error('RBF6:Duplicate','%s line %d duplicates an input',path,source_lines(duplicate(1))); end
if ~isempty(trainX)
    overlap=ismember(X,trainX,'rows');
    if any(overlap), idx=find(overlap,1); error('RBF6:Overlap','%s line %d overlaps training input',path,source_lines(idx)); end
end
d=struct('A',A,'X',X,'Y',A(:,4:9), ...
    'source_lines',source_lines,'source_file',path,'sha256',rbf6_hash(path));
if ~isempty(rule), d=rbf6_apply_labels(d,rule); end
end
