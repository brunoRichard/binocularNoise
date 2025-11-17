function channelmappings = getchannelmappings(hmod,eegchans)

for n = 1:size(eegchans,2)
    labeltofind = upper(eegchans(n).labels);
    for m = 1:size(eegchans,2)
        labeltocheck = hmod.label{m};
        minlength = min(length(labeltofind), length(labeltocheck));
        if labeltofind(1:minlength)==labeltocheck(1:minlength)
            channelmappings(n) = m;
        end
    end
end

end