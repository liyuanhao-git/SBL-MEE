function [err,grad]=errFuncImage(w,y,x)
%
% [IN]
%  w: [nDecoder x 1] weight of decoder
%  x: [nPixel x nDecoder x nSmpl] predicted value of each decoder for N samples.
%  y: [nPixel x nSmpl] true label for nSmpl samples.
%
% option = optimset('Gradobj','on','Hessian','on', 'MaxIter', WMaxIter, 'Display', WDisplay);
% option = optimset('Gradobj','on', 'MaxIter', WMaxIter, 'Display', WDisplay);
% w0 = zeros(1, M);
% [x,fval] = fminunc(@myfun,w0,options);

if nargout>1
    err=0;
    grad=zeros(size(w)); 
    
    for pixIdx=1:size(y,1)        
        h=sum((y(pixIdx,:) - w'*squeeze(x(pixIdx,:,:))).^2,2)/size(y,2);
        dh=-2*sum( repmat((y(pixIdx,:) - w'*squeeze(x(pixIdx,:,:))), length(w),1) .* squeeze(x(pixIdx,:,:)), 2) / size(y,2);
        err=err+h;        
        grad=grad+dh;
    end

    err=err/size(y,1);
    grad=grad(:)/size(y,1);
    % dE/dw_j = -2*Sigma^N_i=1[(y_i-w*x)*x_ij]
else    
    err=0;
    
    for pixIdx=1:size(y,1)
        
        h=sum((y(pixIdx,:)-w'*squeeze(x(pixIdx,:,:))).^2,2)/size(y,2);
        err=err+h;        
    end

  err=err/size(y,1);
end

err=0;
for pixIdx=1:size(x,1)
  err=err + sum((y(pixIdx,:) - w'*squeeze(x(pixIdx,:,:))).^2,2);
end

err=err/size(x,3);

if nargout>1
  grad=zeros(size(w));
  for pixIdx=1:size(x,1)
    grad=grad + -2*sum( repmat((y(pixIdx,:) - w'*squeeze(x(pixIdx,:,:))), length(w),1) .* squeeze(x(pixIdx,:,:)), 2) / size(x,3);
  end
  grad=grad(:);
  % dE/dw_j = -2*Sigma^N_i=1[(y_i-w*x)*x_ij]
end