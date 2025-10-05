function trainLocalDecoder(BasisSet,RoiName,CvMode,AlgoName)

PredLabelSet{1}=1:100;
Parm.exp_p.run_rand=1:20;
Parm.exp_p.onVal=1;
Parm.exp_p.labels_rest_pre=[1,23];
Parm.exp_p.resol=10;
    
% data shuffling or not
Parm.shuffle=0;

% CV for combination of decoders.
switch CvMode
  case 'leave1'
    [TrainRunSet,~]=createCvIdx_nLeaveUnique(Parm.exp_p.run_rand,0,2);
  case 'leave0'
    [TrainRunSet,~]=createCvIdx_nLeaveUnique(Parm.exp_p.run_rand,0,0);
end

%%% loop for basis type
ParmBackBasis=Parm;
for iBasis=1:length(BasisSet)
    %%% reset and initialize parm
    Parm=ParmBackBasis;
    Parm.basis_type=BasisSet{iBasis};
    PredLabel=PredLabelSet{iBasis};

    %%% load data
    load('s1_fmri_roi-1to2mm_Th1_fromAna_s1071119ROI_resol10_v6.mat','D');

    %%% basis setting
    switch Parm.basis_type
      case '1x1'
        Parm.basis=1;
        Parm.conds=[0,1];
      otherwise
        error('invalid basis setting');
    end

    %%% convert basis
    resol=Parm.exp_p.resol;
    [LabelConverted,basis_w]=convertBasis2D_overlap(D.label(:,2:end),[resol,resol],Parm.basis);

    %%% initialize D
    D.label=[D.label(:,1),LabelConverted];
    Parm.basis_convert_w=basis_w;

    %%% Preprocessing parameter setting
    roiEccList={'ecc_lag0','ecc_lag1','ecc_lag2',...
                  'ecc_lag3','ecc_lag4','ecc_lag5',...
                  'ecc_lag6','ecc_lag7','ecc_lag8',...
                  'ecc_lag9','ecc_lag10','ecc_lag11'};
    
    switch RoiName
      case 'AllArea'
        RoiList={'V1','V2','V3','VP','V4'};
        Parm.roi_name='AllArea_Ecc1to11';
      case 'V1V2'        
        RoiList={'V1','V2'};        
        Parm.roi_name='V1V2_Ecc1to11';
      otherwise
        error('Invalid roiAreaName');
    end
    
    RoiMask=false(1,numel(D.roi_name));
    for idx=1:numel(RoiList)
        RoiMask=RoiMask | cellfun(@(x) any(strfind(x,RoiList{idx})),D.roi_name);
    end

    roiEccMask=false(1,numel(D.roi_name));
    for idx=1:numel(roiEccList)
        roiEccMask=roiEccMask | cellfun(@(x) any(strfind(x,roiEccList{idx})),D.roi_name);
    end
    clear idx
    
    Parm.fmri_selectRoi.rois_use{1}={RoiMask};
    Parm.fmri_selectRoi.rois_use{2}={roiEccMask};
    Parm.fmri_selectRoi.within_operation=1;
    Parm.fmri_selectRoi.across_operation=0;

    %%% Outlier rejection
    Parm.reduceOutliers.remove=1;
    Parm.reduceOutliers.method=2;
    Parm.reduceOutliers.app_dim=1;
    Parm.reduceOutliers.min_val=100;
    
    %%% Linear detrend
    Parm.detrend_bdtb.sub_mean=0;
    
    %%% Hemodynamic delay compensation 
    Parm.shiftData.shift=2;
    
    %%% Normalize
    Parm.normByBaseline.mode=0;
    Parm.normByBaseline.base_conds=Parm.exp_p.labels_rest_pre;
    
    procs_list={'fmri_selectRoi';
              'reduceOutliers';
              'detrend_bdtb';
              'shiftData';
              'averageBlocks';
              'normByBaseline'};

    [D,~]=procSwitch(D,Parm,procs_list);
    clear procs_list
    fprintf('--- end of general preprocessing.\n');

    % save preprocessed D for each basisType
    fname_preprocessed_data=sprintf('%s_%s_preprocessed.mat',Parm.roi_name,Parm.basis_type);
    Parm.fname_preprocessed_data=fname_preprocessed_data;
    if ~exist(fname_preprocessed_data,'file')
        save(fname_preprocessed_data,'Parm','D');
    end
    
    % for trainRun loop
    ParmBackTrain=Parm;
    %%% loop for idxTrainRun and idxTestRun.  Don't overwrite parmForLabelLoop in loop!!
    for iTrainRun=1:length(TrainRunSet)

        %%% reset and initialize parm
        Parm=ParmBackTrain;
        idxTrainRun=TrainRunSet{iTrainRun};
        idxTestRun=setdiff(Parm.exp_p.run_rand,idxTrainRun);
        idxFigRun=setdiff(1:D.design(end,ismember(D.design_type,'run')),Parm.exp_p.run_rand);
        fprintf(['Training Runs: ',num2str(idxTrainRun),'\n']);

        % prepare train data (and test data if needed)
        [data_tr.data,data_tr.label,runIdxTr]=getNoRestData(D,idxTrainRun);
        data_tr.label=data_tr.label(:,2:end);
        data_tr.xyz=D.xyz;
        Parm.runIdxTr=runIdxTr;

        if ~isempty(idxTestRun)
            [data_te.data,data_te.label,runIdxTe]=getNoRestData(D,idxTestRun);
            data_te.label=data_te.label(:,2:end);
            data_te.xyz=D.xyz;
            Parm.runIdxTe=runIdxTe;
        end
        if ~isempty(idxFigRun)
            [data_fig.data,data_fig.label,runIdxFig]=getNoRestData(D,idxFigRun);
            data_fig.label=data_fig.label(:,2:end);
            data_fig.xyz=D.xyz;
            Parm.runIdxFig=runIdxFig;
        end

        data_tr.label=data_tr.label/Parm.exp_p.onVal;
        if ~isempty(idxTestRun)
            data_te.label=data_te.label/Parm.exp_p.onVal;
        end
        if ~isempty(idxFigRun)
            data_fig.label=data_fig.label/Parm.exp_p.onVal;
        end

        Parm.idx_train_run=idxTrainRun;
        Parm.idx_test_run=idxTestRun;
        Parm.idx_fig_run=idxFigRun;

        % for prediction label loop
        DataTrLabelLoop=data_tr.data;
        LabelTrLabelLoop=data_tr.label;
        if ~isempty(idxTestRun)
            DataTeLabelLoop=data_te.data;
            LabelTeLabelLoop=data_te.label;
        end
        if ~isempty(idxFigRun)
            DataFigLabelLoop=data_fig.data;
            LabelFigLabelLoop=data_fig.label;
        end
        ParmBackLabel=Parm;

        % loop for idxPredLabel.  Don't overwrite dataTrForLabelLoop and parmForLabelLoop in loop!!
        for iPredLabel=PredLabel
            fprintf(['idxPredLabel -> ',num2str(iPredLabel),'\n']);

            %%% reset and initialize parm
            Parm=ParmBackLabel;
            Parm.i_pred_label=iPredLabel;

            %%% save setting and checking
            TrainRunStr=strrep(num2str(Parm.idx_train_run, ' %1d'), ' ', '-');
            Parm.save_dir=sprintf('%s/label%03d',AlgoName,iPredLabel);
            Parm.save_name=sprintf('%s_label%03d_train%s',CvMode,iPredLabel,TrainRunStr);

            % check save dir
            if ~exist(Parm.save_dir,'dir')
                if ~mkdir(Parm.save_dir)
                    error(['Cannot create directory - ' Parm.save_dir]);
                end
            end
	    
            fprintf('saveDir -> %s\n',Parm.save_dir);
            fprintf('saveName -> %s\n',Parm.save_name);

            data_tr.data=DataTrLabelLoop;
            data_tr.label=LabelTrLabelLoop(:,iPredLabel);
            if ~isempty(idxTestRun)
                data_te.data=DataTeLabelLoop;
                data_te.label=LabelTeLabelLoop(:,iPredLabel);
            end
            if ~isempty(idxFigRun)
                data_fig.data=DataFigLabelLoop;
                data_fig.label=LabelFigLabelLoop(:,iPredLabel);
            end

            %%% Estimating model parameter and testing
            Parm.model = {'slr121a'};
            Parm.slr121a.nlearn=100;
            Parm.slr121a.nstep=10;
            Parm.slr121a.amax=1e8;
            Parm.slr121a.verbose=1;
            Parm.slr121a.conds=Parm.conds;
            Parm.slr121a.normMeanMode='feature';
            Parm.slr121a.normScaleMode='feature';
            Parm.slr121a.normMode='training';
            Parm.slr121a.R=0;
            Parm.slr121a.xcenter=[];
            Parm.slr121a.kernel_func='none';

            % train (random image)
            Parm.modelSwitch.mode = 1;	    
            fprintf('=== Training ===\n')
            [resultsTr,Parm]=modelSwitch(data_tr,Parm,Parm.model,AlgoName);
            
            % test (random image)
            if ~isempty(idxTestRun)
                Parm.modelSwitch.mode=2;
                fprintf('=== Test ===\n')
                [resultsTe,Parm]=modelSwitch(data_te,Parm,Parm.model,AlgoName);
            end
            
            % test (figure image)
            if ~isempty(idxFigRun)
                Parm.modelSwitch.mode=2;
                fprintf('=== Figure test ===\n')
                [resultsFig,Parm]=modelSwitch(data_fig,Parm,Parm.model,AlgoName);
            end            

            %%% save results
            if isempty(idxTrainRun)
	        resultsTr=[];
            end
	        if isempty(idxTestRun)
	        resultsTe=[];
	        end
	        if isempty(idxFigRun)
	        resultsFig=[];
	        end
            
            SaveVars={'Parm','resultsTr','resultsTe','resultsFig'};
            save([Parm.save_dir,'/',Parm.save_name],SaveVars{:});
        end
        clear idxTrainRun idxTestRun idxFigRun
    end
end