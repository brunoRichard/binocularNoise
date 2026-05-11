KbName('UnifyKeyNames');
addpath /Users/tyrion/Documents/MATLAB/Bruno

try
    screenNumber = max(Screen('Screens'));
    PsychImaging('PrepareConfiguration');
    
    oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
    PsychGPUControl('SetDitheringEnabled', 0);
    
    % initialization of the display
    AssertOpenGL
    
    PsychImaging('AddTask', 'General', 'UseDataPixx');
    Datapixx('Open');
    Datapixx('DisableVideoScanningBacklight');      % optionally, turn it off first, in case the refresh rate has changed since startup
    Datapixx('EnableVideoScanningBacklight');       % Only required if a VIEWPixx.
    Datapixx('EnableVideoStereoBlueline');
    Datapixx('SetVideoStereoVesaWaveform', 2);      % If driving NVIDIA glasses
    PsychImaging('AddTask', 'General', 'EnableDataPixxM16OutputWithOverlay');
    if Datapixx('IsViewpixx3D')
        Datapixx('DisableVideoLcd3D60Hz');
        Datapixx('RegWr');
    elseif Datapixx('IsPropixx')
        Datapixx('SetPropixxDlpSequenceProgram',0);
        Datapixx('RegWrRd');
    end
    
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
    [scrn.w, scrn.TheRect] = PsychImaging('OpenWindow', screenNumber, 0, [], [], 2, 1, 0, kPsychNeedFastBackingStore);
    SetStereoBlueLineSyncParameters(scrn.w, scrn.TheRect(4)+10);
    Screen('LoadNormalizedGammaTable', scrn.w, linspace(0,1,256)'*ones(1,3), 0); % THIS IS THE IMPORTANT THING TO DO, NOTE THE LAST ARGUMENT IS 0.
    
    scrn.white = WhiteIndex(screenNumber);
    scrn.black = BlackIndex(screenNumber);
    scrn.gray =  doimagegamma(GrayIndex(screenNumber));
    
    [Xcentre,Ycentre]=WindowCenter(scrn.w);
    Screen('BlendFunction', scrn.w, GL_SRC_ALPHA,GL_ONE_MINUS_SRC_ALPHA);
    scrn.ifi = Screen('GetFlipInterval', scrn.w);
    scrn.ifis = scrn.ifi*1000;
    scrn.hz=Screen('NominalFrameRate', scrn.w);
    params.res=[scrn.TheRect(3) scrn.TheRect(4)];
    params.sze= [52 29.2];% screen size( in cm (width/height))
    params.vdist= 57; % viewing distance (in cm).
    pixsze=params.sze./params.res; %calculates the size of a pixel in cm
    degperpix=(2*atan(pixsze./(2*params.vdist))).*(180/pi);
    scrn.pixperdeg=1./degperpix; % pixels per degree.
    scrn.pixperdeg = scrn.pixperdeg(1);
    priorityLevel=MaxPriority(scrn.w);
    Priority(priorityLevel);
    
    %% Blue Rectangles
    scrn.blueRectLeftOn   = [0, scrn.TheRect(4)-1, scrn.TheRect(3)/4, scrn.TheRect(4)];
    scrn.blueRectLeftOff  = [scrn.TheRect(3)/4, scrn.TheRect(4)-1, scrn.TheRect(3), scrn.TheRect(4)];
    scrn.blueRectRightOn  = [0, scrn.TheRect(4)-1, scrn.TheRect(3)*3/4, scrn.TheRect(4)];
    scrn.blueRectRightOff = [scrn.TheRect(3)*3/4, scrn.TheRect(4)-1, scrn.TheRect(3), scrn.TheRect(4)];
    
    scrn.grayRect = scrn.TheRect + [0 1 0 -1];
    scrn.upperblackrect = [0, scrn.TheRect(2), scrn.TheRect(3), scrn.TheRect(2)+1];
    scrn.lowerblackrect = [0, scrn.TheRect(4)-1, scrn.TheRect(3), scrn.TheRect(4)];
    HideCursor
       
    %% Constant Stimulus Properties
    stim.SZEDeg = 15;
    stim.SZE = round(stim.SZEDeg*scrn.pixperdeg) + mod(round(stim.SZEDeg*scrn.pixperdeg),2)*1;
    stim.GratingSF = 3;
    
    stim.RMS = .15;
    stim.BlankDuration = 1;
    stim.DURATION = 3 + stim.BlankDuration;
    
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
    backGroundtexture(:,:,2) = maskWindow.*scrn.white;
    
    backgroundMask = Screen('MakeTexture', scrn.w, backGroundtexture,[] ,[], 2);
    
    %% Disparity Stuff
    peakPosition = stim.SZE/2;
    disparitySF = .3;
    disparityCPI = disparitySF * (stim.SZE  / scrn.pixperdeg);
    nPixelsPerCycle = (1/(disparityCPI ./ stim.SZE));
    maxDisparity = 5 ;
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
    
    DisparityWindow = zeros(stim.SZE);
    DisparityWindow(:,round(stim.SZE/3):round(stim.SZE/3)*2 -1) = 1;
    SurroundWindow = ~DisparityWindow;
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
    
    windowS = ones(round((stim.SZE+(4*scrn.pixperdeg))));
    windowRect = RectOfMatrix(windowS);
    newWindowRect = CenterRectOnPoint(windowRect,Xcentre+1,Ycentre+1);
    
    currentRow = 0;
    newImageLeft = zeros(stim.SZE);
    newImageRight = zeros(stim.SZE);
    
    stim.temporalF = 3;
    stim.targetFrames = (scrn.hz / stim.temporalF);
    timeS = scrn.ifis:scrn.ifis:scrn.ifis*stim.targetFrames;
    stim.sineProfile = cos(2 .* (pi/1000) .* stim.temporalF .* timeS);
    stim.sineProfile = (stim.sineProfile+1) ./ 2;
    
    noiseIM = rand(stim.SZE);
    fIM_AMP = abs(fft2(noiseIM));
    fIM_PHASE = angle(fft2(noiseIM));
    
    for i = 1:length(stim.sineProfile)
        if mod(i, 6) == 0;
            noiseIM = rand(stim.SZE);
            fIM_AMP = abs(fft2(noiseIM));
            fIM_PHASE = angle(fft2(noiseIM));
        end
%         
        lowPassIM = fIM_AMP .* LOWPASSFILTER;
        lowPassIM(1,1) = 1;
        Phase = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi) .* stim.sineProfile(i)));
        Phase2 = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi) .* stim.sineProfile(i)));
%         Phase  = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE)) .* stim.sineProfile(i)));
%         Phase2 = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE)) .* stim.sineProfile(i)));

        currentRow = 0;
        
        for d = 1:size(stim.gaussianL,2)
            currentRow = currentRow+1;
            rowIDX = mod(currentRow-1, size(stim.gaussianL,3))+1;
            
            LeftImageFFT = lowPassIM .* fft2(stim.gaussianL(:,:,rowIDX));
            RightImageFFT = lowPassIM .* fft2(stim.gaussianR(:,:,rowIDX));
            DnewImage = real(ifft2(LeftImageFFT .* exp(1i * Phase)));
            DnewImage = DnewImage./max(max(abs(DnewImage))) ./2;
            DnewImage2 = real(ifft2(RightImageFFT .* exp(1i * Phase2)));
            DnewImage2 = DnewImage2./max(max(abs(DnewImage2))) ./2;
            
            newImageLeft(currentRow,:) = DnewImage(currentRow,:);
            newImageRight(currentRow,:) = DnewImage2(currentRow,:);
        end
        
        newImageLeft = newImageLeft./max(max(abs(newImageLeft)))./2;
        RMS_altered = std2(newImageLeft+.5)./mean2(newImageLeft+.5);
        rms_alt_scale = (stim.RMS*3)/RMS_altered;
        newImageDLeft = ((newImageLeft.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;
        
        newImageRight = newImageRight./max(max(abs(newImageRight)))./2;
        RMS_altered = std2(newImageRight+.5)./mean2(newImageRight+.5);
        rms_alt_scale = (stim.RMS*3)/RMS_altered;
        newImageDRight = ((newImageRight.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;
        
        R = corrcoef(newImageDLeft, newImageDRight);
        
        CORR(i) = R(1,2);
          
        noiseIM1(i) = Screen('MakeTexture', scrn.w, newImageDLeft,[],[],2);
        noiseIM2(i) = Screen('MakeTexture', scrn.w, newImageDRight,[],[],2);
    end
    
    Screen('SelectStereoDrawBuffer', scrn.w, 0) ;
    Screen('FillRect', scrn.w, scrn.gray);
    Screen('DrawTexture', scrn.w, backgroundMask);
    Screen('DrawDots', scrn.w, [Xcentre, Ycentre], FixationSize, [0,0,0]);
    Screen('FrameOval', scrn.w, [0 0 0], newWindowRect ,2);
    Screen('FillRect', scrn.w, [255 255 255], scrn.blueRectLeftOn);
    Screen('FillRect', scrn.w, [0 0 0], scrn.blueRectLeftOff);
    Screen('SelectStereoDrawBuffer', scrn.w, 1);
    Screen('FillRect', scrn.w, scrn.gray);
    Screen('DrawTexture', scrn.w, backgroundMask);
    Screen('DrawDots', scrn.w, [Xcentre, Ycentre], 10, [0,0,0]);
    Screen('FrameOval', scrn.w, [0 0 0], newWindowRect ,2);
    Screen('FillRect', scrn.w, [255 255 255], scrn.blueRectRightOn);
    Screen('FillRect', scrn.w, [0 0 0], scrn.blueRectRightOff);
    Screen('Flip', scrn.w);
    
    KbPressWait
    
    currentFrame = 0;
    while  currentFrame <= stim.DURATION*scrn.hz
        currentFrame = currentFrame + 1;
        frameIDX = mod(currentFrame-1, stim.targetFrames)+1;
        %%%%%%%%%%%%%%% Left Eye %%%%%%%%%%%%%%%
        Screen('SelectStereoDrawBuffer', scrn.w, 0) ;
        Screen('FillRect', scrn.w, scrn.gray);
        
        Screen('DrawTexture', scrn.w, noiseIM1(frameIDX));
        
        Screen('DrawTexture', scrn.w, backgroundMask);
        Screen('DrawDots', scrn.w, [Xcentre, Ycentre], FixationSize, [0,0,0]);
        Screen('FrameOval', scrn.w, [0 0 0], newWindowRect ,2);
        
        Screen('FillRect', scrn.w, [255 255 255], scrn.blueRectLeftOn);
        Screen('FillRect', scrn.w, [0 0 0], scrn.blueRectLeftOff);
        
        %%%%%%%%%%%%%%% Right Eye %%%%%%%%%%%%%%%
        Screen('SelectStereoDrawBuffer', scrn.w, 1);
        Screen('FillRect', scrn.w, scrn.gray);
        
        Screen('DrawTexture', scrn.w, noiseIM2(frameIDX));
        
        Screen('DrawTexture', scrn.w, backgroundMask);
        Screen('DrawDots', scrn.w, [Xcentre, Ycentre], 10, [0,0,0]);
        Screen('FrameOval', scrn.w, [0 0 0], newWindowRect ,2);
        
        Screen('FillRect', scrn.w, [255 255 255], scrn.blueRectRightOn);
        Screen('FillRect', scrn.w, [0 0 0], scrn.blueRectRightOff);
        
        Screen('DrawingFinished', scrn.w);
        
        %%%%%%%%%%%%%%% Flip %%%%%%%%%%%%%%%
        Screen('Flip', scrn.w);
        [~, ~, keyCode] = KbCheck;
        
        if keyCode(KbName('Escape'))
            Screen('CloseAll');
            ListenChar(1);
            Priority(0);
        end
    end
catch
    Screen('CloseAll')
    close all
    psychrethrow(psychlasterror);
end
Screen('CloseAll')