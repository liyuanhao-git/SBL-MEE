function predictVal=predictSmlr(decoder,smpl,mode)

NumSamples=size(smpl,1);
NumClass=numel(decoder.parm.conds);
parm=decoder.parm.slr121a;

KernelFunc=getFieldDef(parm,'kernel_func','none');
R=getFieldDef(parm,'R',0);
xcenter=getFieldDef(parm,'xcenter',[]);

normMeanMode=getFieldDef(parm,'normMeanMode','feature');
normScaleMode=getFieldDef(parm,'normScaleMode','feature');
normMean=getFieldDef(parm,'normMean',0);
normScale=getFieldDef(parm,'normScale',1);
normMode=getFieldDef(parm,'normMode','training');

weight=getFieldDef(parm,'weight',[]);
IdxEff=getFieldDef(parm,'ix_eff',[]);

  if strcmp(normMode,'test')
    if size(smpl,1)==1 && strcmp(normMeanMode,'each')
      fprintf('\nWARNINIG: data sample size is 1. this normalization convnert all features into 0.\n');
    end
    smpl=normFeature(smpl,normMeanMode,normScaleMode);
  elseif strcmp(normMode,'training')
    smpl=normFeature(smpl,normMeanMode,normScaleMode,normMean,normScale);
  else
    error('normalization mode error');
  end  

if NumClass==2
    % binomial
    if strcmp(KernelFunc,'none')
        Phi=smpl;
    else
        Phi=slr_make_kernel(smpl,KernelFunc,xcenter,R);
    end
    Phi=[Phi,ones(NumSamples,1)];

    if isempty(IdxEff)
        pred=zeros(NumSamples,1);
        dec_val=zeros(NumSamples,1);
    else
        if size(weight,1)>size(Phi,2)
            weight=weight(IdxEff);      
        end
        dec_val=1./(1+exp(-Phi*weight));
        pred=double(dec_val>0.5);
    end
else
    % multinomial
    Phi=[smpl ones(NumSamples,1)];
    [~,label_est_te]=max(Phi*weight,[],2);

    eY=exp(Phi*weight); % num_samples*num_class
    dec_val=eY./repmat(sum(eY,2), [1, NumClass]); % num_samples*num_class
    pred=decoder.parm.conds(label_est_te)';
end

% calc expected value
if isfield(decoder,'labelList')
    switch mode
      case 'maxProbLabel'
        predictVal=pred; %% edYM
      case 'exProb'
        if NumClass==2
           predictVal=dec_val; %% edYM
        else            
            predictVal=dec_val*decoder.labelList';
        end
      otherwise
        error('Invalid prediction mode: should be maxProbLabel or exProb');
    end
else
  error('ERROR: incompatible to non-labeled data -- in predict_smlr.m');
end
end