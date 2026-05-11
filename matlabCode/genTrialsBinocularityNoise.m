function noiseIMs = genTrialsBinocularityNoise(scrn, stim, LOWPASSFILTER)

noiseIM = rand(stim.SZE);
fIM_AMP = abs(fft2(noiseIM));
fIM_PHASE = angle(fft2(noiseIM));

for j = 1:6
    for i = 1:length(stim.sineProfile);
        if mod(i, 6) == 0;
            noiseIM = rand(stim.SZE);
            fIM_AMP = abs(fft2(noiseIM));
            fIM_PHASE = angle(fft2(noiseIM));
        end
        %
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
        
        noiseIMs(1).IM1(:,:,j,i) = newImage1;
        noiseIMs(1).IM2(:,:,j,i) = newImage22;
        
        %% notcorrelated to correlated with disparity
        currentRow = 0;
        newImageLeft = zeros(stim.SZE);
        newImageRight = zeros(stim.SZE);
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
        
        R2 = corrcoef(newImageDLeft, newImageDRight);
        noiseIMs(2).ImageCorrelation(i) = R2(1,2);
        
        noiseIMs(2).IM1(:,:,j,i) = newImageDLeft;
        noiseIMs(2).IM2(:,:,j,i) = newImageDRight;
        
        %% anticorrelated to correlated no disparity
        %% anticorrelated to correlated no disparity
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
        noiseIMs(3).ImageCorrelation(i) = R(1,2);
        
        noiseIMs(3).IM1(:,:,j,i) = newImage1;
        noiseIMs(3).IM2(:,:,j,i) = newImage22;
        
        %% Control
        
        Phase = fIM_PHASE + MAKE_SYMMETRIC(((rand(stim.SZE).*(pi*2)-pi) .* stim.sineProfile(i)));
        newImage = real(ifft2(lowPassIM .* exp(1i * Phase)));
        
        newImage = newImage./max(max(abs(newImage)))./2;
        RMS_altered = std2(newImage+.5)./mean2(newImage+.5);
        rms_alt_scale = (stim.RMS*3)/RMS_altered;
        newImage1 = ((newImage.*(rms_alt_scale)).*stim.Window).*scrn.gray+scrn.gray;
        
        
        R = corrcoef(newImage1, fliplr(newImage1));
        noiseIMs(13).ImageCorrelation(i) = R(1,2);
        
        noiseIMs(13).IM1(:,:,j,i) = newImage1;
        noiseIMs(13).IM2(:,:,j,i) = fliplr(newImage1);
        
        
    end
end

save('BinocularityNoiseImages3', 'noiseIMs', '-v7.3');



