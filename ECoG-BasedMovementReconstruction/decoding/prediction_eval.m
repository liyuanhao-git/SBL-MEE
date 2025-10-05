function [yytestPre,CorrTest,RmseTest]=prediction_eval(ww,xxtest_zs,meanyyTrain,stdyyTrain,yytest)

% Prediction
yytestPre=xxtest_zs*ww*diag(stdyyTrain)+ones(size(xxtest_zs,1),1)*meanyyTrain;
    
% Evaluation
CorrTemp=corrcoef(yytestPre,yytest);
CorrTest=CorrTemp(2);
RmseTest=sqrt(sum((yytestPre-yytest).^2)/size(yytest,1));
end