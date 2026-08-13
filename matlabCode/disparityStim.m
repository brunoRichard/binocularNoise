scrn.pixperdeg = 36.7325;
stim.SZEDeg = 15;
stim.SZE = round(stim.SZEDeg*scrn.pixperdeg) + mod(round(stim.SZEDeg*scrn.pixperdeg),2)*1;
stim.GratingSF = 3;
stim.RMS = .15;
scrn.gray = .7367;

[ru, rv] = meshgrid(0:(max(stim.SZE)/2),0:(max(stim.SZE)/2));
[~, Radius] = cart2pol(ru,rv);
Radius = [Radius, fliplr(Radius(:,2:(max(stim.SZE)/2)))];
Radius = [Radius; flipud(Radius(2:(max(stim.SZE)/2),:))];
Radius = fftshift(Radius);
Radius_i = round(Radius);
radius = fftshift(Radius_i); 
radius(1,1) = 1;
LOWPASSFILTER = fftshift(double(((Radius_i./max(max(Radius_i)))*(scrn.pixperdeg/2))) <  stim.GratingSF);
radius = fftshift(radius);

 %% Stimulus Window
    FixationSize=10;
    InnerLimitRadius = FixationSize *2;
    OuterLimitRadius = stim.SZE/2;
    rampSize = (1/3 * 11) / stim.SZE; % 20 arcmin
    mea = 0;
    BS = rampSize * stim.SZE;
    stim.Window = ones(round(stim.SZE));
    for x = 1:stim.SZE
        for y = 1:stim.SZE
            if radius(x,y) >= (OuterLimitRadius - BS)
                n = OuterLimitRadius - radius(x,y);
                stim.Window(x,y) = (((BS-n)/BS)*mea)+((n/BS)*1);
            end
            if radius(x,y) <= InnerLimitRadius && radius(x,y) > InnerLimitRadius-BS
                n = BS-(InnerLimitRadius-radius(x,y));
                stim.Window(x,y) = (((BS-n)/BS)*mea)+((n/BS)*1);
            end
            if radius(x,y) > OuterLimitRadius || radius(x,y) < InnerLimitRadius-BS
                stim.Window(x,y) = mea;
            end
        end
    end

%% Disparity Stuff
peakPosition = stim.SZE/2;
disparitySF = .3;
disparityCPI = disparitySF * (stim.SZE  / scrn.pixperdeg);
nPixelsPerCycle = (1/(disparityCPI ./ stim.SZE));
maxDisparity = 2 ;
Xdisparity = maxDisparity * cos(2*(pi/scrn.pixperdeg)*disparitySF * linspace(0,nPixelsPerCycle,nPixelsPerCycle));
Ydisparity = 0;  sigma = .1 ;
X = -stim.SZE/2:stim.SZE/2-1;
Y = X;

[xG, yG] = meshgrid(X,Y);
for Xd = 1:length(Xdisparity)
    xGaussL = ((xG - Xdisparity(Xd)).^2)./(2*sigma^2);
    yGaussL = ((yG - Ydisparity).^2)./(2*sigma^2);
    stim.gaussianL(:,:, Xd) =  exp(-(xGaussL + yGaussL));
    xGaussR = ((xG + Xdisparity(Xd)).^2)./(2*sigma^2);
    yGaussR = ((yG + Ydisparity).^2)./(2*sigma^2);
    stim.gaussianR(:,:,Xd) = exp(-(xGaussR + yGaussR));
end

currentRow = 0;
newImageLeft = zeros(stim.SZE);
newImageRight = zeros(stim.SZE);

noiseIM = rand(stim.SZE);
fIM_AMP = abs(fft2(noiseIM));
fIM_PHASE = angle(fft2(noiseIM));

lowPassIM = fIM_AMP .* LOWPASSFILTER;
lowPassIM(1,1) = 1;
Phase = fIM_PHASE;

currentRow = 0;

for d = 1:size(stim.gaussianL,2)
    currentRow = currentRow+1;
    rowIDX = mod(currentRow-1, size(stim.gaussianL,3))+1;

    LeftImageFFT = lowPassIM .* fft2(stim.gaussianL(:,:,rowIDX));
    RightImageFFT = lowPassIM .* fft2(stim.gaussianR(:,:,rowIDX));
    DnewImage = real(ifft2(LeftImageFFT .* exp(1i * Phase)));
    DnewImage = DnewImage./max(max(abs(DnewImage))) ./2;
    DnewImage2 = real(ifft2(RightImageFFT .* exp(1i * Phase)));
    DnewImage2 = DnewImage2./max(max(abs(DnewImage2))) ./2;

    newImageLeft(currentRow,:) = DnewImage(currentRow,:);
    newImageRight(currentRow,:) = DnewImage2(currentRow,:);
end

newImageLeftNormalized = (newImageLeft-min(min(newImageLeft)))/max(max((newImageLeft-min(min(newImageLeft)))));
imMean = mean2(newImageLeftNormalized);
imSD = std2(newImageLeftNormalized);
leftIMAdjusted = (newImageLeftNormalized - imMean) .* (stim.RMS/imSD);
finalImageLeft = (leftIMAdjusted .* stim.Window)*scrn.gray + scrn.gray;
finalImageLeft(finalImageLeft > 1) = 1;
finalImageLeft(finalImageLeft < 0) = 0;

newImageRightNormalized = (newImageRight-min(min(newImageRight)))/max(max((newImageRight-min(min(newImageRight)))));
imMean = mean2(newImageRightNormalized);
imSD = std2(newImageRightNormalized);
rightIMAdjusted = (newImageRightNormalized - imMean) .* (stim.RMS/imSD);
finalImageRight = (rightIMAdjusted .* stim.Window)*scrn.gray + scrn.gray;
finalImageRight(finalImageRight > 1) = 1;
finalImageRight(finalImageRight < 0) = 0;

J = stereoAnaglyph(finalImageLeft,finalImageRight);
imagesc(J)