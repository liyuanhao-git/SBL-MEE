function [results,pars]=slr121a(D,pars,AlgoName)
conds=getFieldDef(pars,'conds',unique(D.label));
mode=getFieldDef(pars,'mode',1);
verbose=getFieldDef(pars,'verbose',0);

norm_mean_mode=getFieldDef(pars,'normMeanMode','feature');
norm_scale_mode=getFieldDef(pars,'normScaleMode','feature');
norm_mean=getFieldDef(pars,'normMean',0);
norm_scale=getFieldDef(pars,'normScale',1);
norm_mode=getFieldDef(pars,'normMode','training');
nlearn=getFieldDef(pars,'nlearn',100);

NumClass=length(conds);

% SLR pars:
if NumClass==2
    % binomial only
    R=getFieldDef(pars,'R',0);      % Gaussian width parameter
    xcenter=getFieldDef(pars,'xcenter',[]);
    kernel_func=getFieldDef(pars,'kernel_func','none');
end
weight=getFieldDef(pars,'weight',[]);
IdxEff=getFieldDef(pars,'ix_eff',[]);

if mode==1 && isempty(D.label)
    error('must have ''label'' for train');
elseif mode==2 && isempty(weight)
    error('must have ''weight'' for test');
end

[label,conds2]=reIndex(D.label,[],conds);
if NumClass==2
    label=label-1;
    conds2=[0,1];
end
ind=ismember(label,conds2);
label2=label(ind);
data2=D.data(ind,:);
NumSamples=length(label2);

% Test mode:
if mode==2
    if strcmp(norm_mode,'test')
        if size(data2,1)==1 && strcmp(norm_mean_mode,'each')
            fprintf('\nWARNINIG: data sample size is 1. this normalization convnert all features into 0.\n');
        end
        data2=normFeature(data2,norm_mean_mode,norm_scale_mode);
    elseif strcmp(norm_mode,'training')
        data2=normFeature(data2,norm_mean_mode,norm_scale_mode,norm_mean,norm_scale);
    else
        error('normalization mode error');
    end  
    
    % binomial
    if NumClass==2
        if strcmp(kernel_func,'none')     
            Phi=data2;
        else
            Phi=slr_make_kernel(data2,kernel_func,xcenter,R);
        end
        Phi=[Phi,ones(NumSamples,1)];
    
        if isempty(IdxEff)
            szl=size(label2);
            NumCorrect=0;
            pred=zeros(szl);
            dec_val=zeros(szl);
        else
            if size(weight,1)>size(Phi,2)
                weight=weight(IdxEff);      
            end
            [NumCorrect,pred,dec_val]=slr_count_correct(label2,Phi,weight);
        end
    end    

    CorrectRate=NumCorrect/NumSamples*100;    
    if verbose  
        fprintf(' Answer correct in test: %g%%\n',CorrectRate);       
    end

% Train mode:
else
  % normalize
  [data2,norm_mean,norm_scale]=normFeature(data2,norm_mean_mode,norm_scale_mode);

  if NumClass==2
      % binomial
      if strcmp(kernel_func,'none')
          Phi=data2;
      else
          Phi=slr_make_kernel(data2,kernel_func,xcenter,R);
      end
      Phi=[Phi,ones(NumSamples,1)];
      
      switch AlgoName
          case 'SBL'
          [weight,IdxEff]=learning_sbl_classification(label2,Phi,nlearn);
          case 'SBCL'
          [weight,IdxEff]=learning_sbcl_classification(label2,Phi,nlearn);
          case 'SBLMEE'
          [weight,IdxEff]=learning_sblmee_classification(label2,Phi,nlearn);
      end
      
      if isempty(IdxEff)
          szl=size(label2);
          NumCorrect=0;
          pred=zeros(szl);
          dec_val=zeros(szl);
      else
          [NumCorrect,pred,dec_val]=slr_count_correct(label2,Phi,weight);
      end
      
      CorrectRate=NumCorrect/NumSamples*100;
      pars.normMean=norm_mean;
      pars.normScale=norm_scale;
      pars.weight=weight;
      pars.ix_eff=IdxEff;

      if strcmp(kernel_func,'Gaussian')
          pars.xcenter=data2(IdxEff(1:end-1),:);    
      end
  end
end

% Return results:
results.model=mfilename;
results.label=D.label;
results.weight=weight;
results.dec_val=dec_val;
results.xyz=D.xyz;
results.pred=pred;

% For 'P'ars-struct
if exist('P','var')
    P.(mfilename)=pars;
end