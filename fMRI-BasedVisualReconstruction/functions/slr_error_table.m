function Table=slr_error_table(label_true,label_est)
label_pair=[label_true,label_est];
label_names=unique(label_pair(:));
Nclass=length(label_names);

for ii=1:Nclass
    for jj=1:Nclass
          ix=find(label_pair(:,1) == label_names(ii) & label_pair(:,2) == label_names(jj));        
          Table(ii,jj)=length(ix);
    end
end
end