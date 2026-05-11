%make demo stimuli

scrn.pixperdeg = 36.7325;
scrn.hz = 120;
scrn.ifi = 0.0083;
scrn.ifis = 8.332;
scrn.gray = 0.7367; %0.5?
scrn.TheRect = [0 0 1920 1080];

% Stimulus properties
stim.SZEDeg = 15;
stim.SZE = round(stim.SZEDeg*scrn.pixperdeg) + mod(round(stim.SZEDeg*scrn.pixperdeg),2)*1;
stim.GratingSF = 3;
stim.RMS = .15;
stim.BlankDuration = 3;
stim.DURATION = 11 + stim.BlankDuration;
stim.temporalF = 3;

%
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

% Sinusoidal Profile
stim.targetFrames = (scrn.hz / stim.temporalF);
timeS = scrn.ifis:scrn.ifis:scrn.ifis*stim.targetFrames;
stim.sineProfile = cos(2 .* (pi/1000) .* stim.temporalF .* timeS);
stim.sineProfile = (stim.sineProfile+1) ./ 2;

% Background Image
[ruB, rvB] = meshgrid(0:(max(scrn.TheRect)/2),0:(max(scrn.TheRect)/2));
[~, RadiusB] = cart2pol(ruB,rvB);
RadiusB = [RadiusB, fliplr(RadiusB(:,2:(max(scrn.TheRect)/2)))];
RadiusB = [RadiusB; flipud(RadiusB(2:(max(scrn.TheRect)/2),:))];
RadiusB = fftshift(RadiusB);
Radius_iB = round(RadiusB);
radiusB = fftshift(Radius_iB);
radiusB(1,1) = 1;
LOWPASSFILTERb = double(radiusB < 10);

noisePattern = rand(max(scrn.TheRect), max(scrn.TheRect));
fIMA =fft2(noisePattern);
FF = abs(fIMA) .* LOWPASSFILTERb;
FF(1,1) = fIMA(1,1);
filtNoisePattern =  real(ifft2(FF .* exp(1i .* angle(fft2(noisePattern))))) ;
filtNoisePattern = mat2gray(filtNoisePattern)>.5;
phaseFiltNoisePattern = angle(fft2(filtNoisePattern));
newAMP = fftshift(1 ./ Radius_iB .^1);
newAMP(1,1) = 0;
newImage = real(ifft2(newAMP .* exp(1i.*phaseFiltNoisePattern)));
backGroundtexture = (newImage ./ max(max(newImage)))*scrn.gray+scrn.gray;
maskWindow = Radius_iB > (stim.SZE+(4*scrn.pixperdeg))/2 ;

noiseIM = rand(stim.SZE);
fIM_AMP = abs(fft2(noiseIM));
fIM_PHASE = angle(fft2(noiseIM));

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


for i = 1:length(stim.sineProfile)


    %% Uncorrelated to correlated no disparity

    lowPassIM = fIM_AMP .* LOWPASSFILTER;
    lowPassIM(1,1) = 1;

    Phase = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi) .* stim.sineProfile(i)));
    Phase2 = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi) .* stim.sineProfile(i)));

    newImage = real(ifft2(lowPassIM .* exp(1i * Phase)));
    newImage2 = real(ifft2(lowPassIM .* exp(1i * Phase2)));

    newImage = newImage./max(max(abs(newImage)))./2;
    RMS_altered = std2(newImage+.5)./mean2(newImage+.5);
    rms_alt_scale = (stim.RMS*3)/RMS_altered;
    newImage1 = ((newImage.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;

    newImage2 = newImage2./max(max(abs(newImage2)))./2;
    RMS_altered = std2(newImage2+.5)./mean2(newImage2+.5);
    rms_alt_scale = (stim.RMS*3)/RMS_altered;
    newImage22 = ((newImage2.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;

    R = corrcoef(newImage1, newImage22);
    noiseIMs(1).ImageCorrelation(i) = R(1,2);

    % minMaxScaled1 = 0 + (1-0) * (newImage1-min(min(newImage1)))/(max(max(newImage1))-min(min(newImage1)));
    % minMaxScaled2 = 0 + (1-0) * (newImage1-min(min(newImage22)))/(max(max(newImage22))-min(min(newImage22)));


    noiseIMs(1).IM1(:,:,i) = newImage1;
    noiseIMs(1).IM2(:,:,i) = newImage22;

    %% Anticorrelated to no correlation
    Phase = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi))) .* max(stim.sineProfile(i));
    Phase2 = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi))) .* max(stim.sineProfile(i));

    newImage = real(ifft2(lowPassIM .* exp(1i * Phase)));
    newImage2 = real(ifft2(lowPassIM .* exp(1i * Phase2))).*-1;

    newImage = newImage./max(max(abs(newImage)))./2;
    RMS_altered = std2(newImage+.5)./mean2(newImage+.5);
    rms_alt_scale = (stim.RMS*3)/RMS_altered;
    newImage1 = ((newImage.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;

    newImage2 = newImage2./max(max(abs(newImage2)))./2;
    RMS_altered = std2(newImage2+.5)./mean2(newImage2+.5);
    rms_alt_scale = (stim.RMS*3)/RMS_altered;
    newImage22 = ((newImage2.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;

    R = corrcoef(newImage1, newImage22);
    noiseIMs(2).ImageCorrelation(i) = R(1,2);

    % minMaxScaled1 = 0 + (1-0) * (newImage1-min(min(newImage1)))/(max(max(newImage1))-min(min(newImage1)));
    % minMaxScaled2 = 0 + (1-0) * (newImage1-min(min(newImage22)))/(max(max(newImage22))-min(min(newImage22)));

    noiseIMs(2).IM1(:,:,i) = newImage1;
    noiseIMs(2).IM2(:,:,i) = newImage22;
end

%fname = "~/Library/CloudStorage/Box-Box/Manuscripts/Binocular Noise Study/Figures/noiseImages.mat";
fname = "C:\Users\Bruno\Box\Manuscripts\Binocular Noise Study\Figures\noiseImages2.mat";
save(fname, 'noiseIMs', 'stim', 'backGroundtexture', 'maskWindow')