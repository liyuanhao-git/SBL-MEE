function extractDecoder(BasisTypeSet,CvMode,AlgoName)

SaveFDirPost='Decoder';
TrainRun=1:20;
ResultsDir=AlgoName;

% main loop
for iBasisType=1:length(BasisTypeSet)
    BasisType=BasisTypeSet{iBasisType};
	
    switch BasisType
      case '1x1'
        LabelsList=1:100;
    end       
    
    switch CvMode
      case 'leave1'
        [TrainRunSet,TrainRunSetStr]=createCvIdx_nLeaveUnique(TrainRun,0,2);
      case 'leave0'
        [TrainRunSet,TrainRunSetStr]=createCvIdx_nLeaveUnique(TrainRun,0,0);
    end

    labelsAll=[];
    labelsPreAll=[];
    labelsPreExpAll=[];
    for iCv=1:length(TrainRunSet)
        TrainRunStr=TrainRunSetStr{iCv};
        decoder={};
        for iLabel=LabelsList
            FileName=sprintf('label%03d/%s_label%03d_train%s',iLabel,CvMode,iLabel,TrainRunStr);
            fprintf(['loading ... ' FileName ' \n']);
            res=load([ResultsDir '/' FileName '.mat']);
            decoder{iLabel}=struct;
            decoder{iLabel}.model=res.Parm.model;

            if strcmp(res.Parm.model,'slr121a')
                decoder{iLabel}.weight=res.resultsTr{1}.weight;
                decoder{iLabel}.parm=res.Parm;
            end
            eval(['decoder{iLabel}.' decoder{iLabel}.model{:} ' = res.Parm.' decoder{iLabel}.model{:} ';']);
            decoder{iLabel}.xyz=res.resultsTr{1}.xyz;
        end

        BasisMat=res.Parm.basis_convert_w;
        OrigData=ResultsDir;
        if ~exist([ResultsDir SaveFDirPost],'dir')
            mkdir([ResultsDir SaveFDirPost]);
        end
        save([ResultsDir SaveFDirPost '/' CvMode '_' BasisType '_' TrainRunStr],'decoder','BasisMat','OrigData');
    end
end
end