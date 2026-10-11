function h = rbf6_hash(path)
f=fopen(path,'rb'); if f<0, error('RBF6:File','Cannot open %s',path); end
cleanup=onCleanup(@()fclose(f)); data=fread(f,Inf,'*uint8');
md=java.security.MessageDigest.getInstance('SHA-256'); md.update(data);
bytes=typecast(md.digest(),'uint8'); h=lower(reshape(dec2hex(bytes,2)',1,[]));
end
