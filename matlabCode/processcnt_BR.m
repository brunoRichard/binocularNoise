function processcnt_BR(dirpath,subj)

if ispc
    hash = '\';
else
    hash = '/';
end

cd([dirpath hash subj]);
dcnt = dir('*.cnt');
dtrg = dir('*.trg');
BLOCK = 1:length(dcnt);
load ANTmontage.mat

fName = [dirpath subj hash dcnt(n).name];
if ~isempty(dcnt)
    for n = 1:length(dcnt)
        tempeeg = read_eep_cnt(dcnt(n).name);
        EEG = read_eep_cnt(dcnt(n).name,1,tempeeg.nsample);

        EEG = pop_loadeep_v4(fName);
        EEG.data = single(EEG.data);        % halves the disc space required - this is what EEG lab does automatically and doesn't make any difference as far as I can tell
        
        tempevent = read_eep_trg(dtrg(n).name);
        for ev = 1:length(tempevent)
            EEG.event(ev).type = tempevent(ev).code;
            EEG.event(ev).latency = tempevent(ev).time;
        end
        EEG.chanlocs = chanlocs;
        EEG.lay = lay;
        save(strcat(dirpath,hash,subj,hash,'EEG_',subj,'BLOCK',num2str(BLOCK(n)),'.mat'),'EEG');
        clear EEG;
    end
end
