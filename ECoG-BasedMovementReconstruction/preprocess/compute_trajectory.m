function [traFinal,MotionTime]=compute_trajectory(traOriginal,MotionTime,downFs)

% make a null array to store the processed trajectory
trajectory=zeros(size(traOriginal{6}));

% compute the Z-direction trajectory
trajectory(:,3)=traOriginal{6}(:,3)-(traOriginal{1}(:,3)+traOriginal{4}(:,3))/2;

% compute the X-direction trajectory and Y-direction trajectory
traLeftSho=traOriginal{1}(:,1:2);
traRightSho=traOriginal{4}(:,1:2);
traRightWri=traOriginal{6}(:,1:2);

normShoulder = sqrt((traRightSho(:,1)-traLeftSho(:,1)).^2+(traRightSho(:,2)-traLeftSho(:,2)).^2);
x_vec=[(traRightSho(:,1)-traLeftSho(:,1))./normShoulder (traRightSho(:,2)-traLeftSho(:,2))./normShoulder];
y_vec=[(traLeftSho(:,2)-traRightSho(:,2))./normShoulder (traRightSho(:,1)-traLeftSho(:,1))./normShoulder];

original=[traRightWri(:,1)-(traRightSho(:,1)+traLeftSho(:,1))/2 traRightWri(:,2)-(traLeftSho(:,2)+traRightSho(:,2))/2];
trajectory(:,1)=original(:,1).*x_vec(:,1)+original(:,2).*x_vec(:,2);
trajectory(:,2)=original(:,1).*y_vec(:,1)+original(:,2).*y_vec(:,2);
clear traLeftSho traRightSho traRightWri normShoulder x_vec y_vec original

% 120Hz-15min data
midPointTra=round(size(MotionTime,2)/2);
startPointTra=midPointTra-(120*60*15)/2+1;
endPointTra=midPointTra+(120*60*15)/2;
clear midPointTra

% compute the temporal point after downsampling
trajectory=trajectory(startPointTra:endPointTra,:);
MotionTime=MotionTime(startPointTra:endPointTra);
clear startPointTra endPointTra

downIndex=1:(120/downFs):size(MotionTime,2);
MotionTime=MotionTime(downIndex);
clear downIndex

% low-pass filtering
filterOrder=1000;
Wn=5/(120/2);
bb=fir1(filterOrder,Wn,'low');
traFiltered=filtfilt(bb,1,trajectory);

% downsampling on trajectory data
traFinal=resample(traFiltered,downFs,120);

% normalize the trajectory matrix
traFinal=traFinal-repmat(mean(traFinal,1),size(traFinal,1),1);
traFinal=traFinal./repmat(std(traFinal),size(traFinal,1),1);
end