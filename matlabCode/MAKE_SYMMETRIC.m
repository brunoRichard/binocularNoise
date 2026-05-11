function SYMMETRISIZE = MAKE_SYMMETRIC(matrix)

[h w d] = size(matrix);
extrapixl = (h+1);
midC = h/2;
after_midC1 = ((h/2)+1);
after_midC2 = ((h/2)+2);

tmp_phse1 = matrix;
tmp_phse2 = zeros(extrapixl,extrapixl);
tmp_phse2(1:h,1:w) = tmp_phse1.*(-1);
tmp_phse2(after_midC2:extrapixl,1:w) = flipud(tmp_phse2(1:midC,1:w));
tmp_phse2(after_midC2:extrapixl,1:extrapixl) = fliplr(tmp_phse2(after_midC2:extrapixl,1:extrapixl));
tmp_phse2(after_midC2:extrapixl,1:1) = flipud(tmp_phse2(1:midC,1:1));
tmp_phse2(after_midC1:after_midC1,1:midC) = fliplr(tmp_phse2(after_midC1:after_midC1,after_midC2:extrapixl));
tmp_phse2(1:midC,1:w) = tmp_phse1(1:midC,1:w);
tmp_phse2(1:1,1:midC) = fliplr(tmp_phse2(1:1,after_midC2:extrapixl))*(-1);
tmp_phse2(after_midC1:after_midC1,1:midC) = fliplr(tmp_phse2(after_midC1:after_midC1,after_midC2:extrapixl))*(-1);
SYMMTRC_RAND_PHASE(1:w,1:w) = tmp_phse2(1:h,1:w);
SYMMTRC_RAND_PHASE(1,after_midC1) = 0;
SYMMTRC_RAND_PHASE(after_midC1,after_midC1) = 0;

SYMMETRISIZE = SYMMTRC_RAND_PHASE;

