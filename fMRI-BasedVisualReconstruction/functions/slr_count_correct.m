function [Ncorrect,label_est,prob,y]=slr_count_correct(label,X,w)
y=X*w;
prob=1./(1+exp(-y));
label_est=prob>0.5;
v=~xor(label,label_est);
Ncorrect=sum(v);
end