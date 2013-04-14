function batchrun(subjinfo)

loadpaths
loadsubj
numrand = 1000;

if ischar(subjinfo)
    subjlist = {subjinfo};
else
    subjlist = subjlists{subjinfo};
end

condlist = {
    'TRG1' 'explicit'
    'TRG2' 'implicit'
    'DIST' 'distractor'
};

timewin = {
   [100 400]
   [400 700]
};

% for c = 1:size(condlist,1)
%     %     for t = 1:length(timewin)
%     %         compgfp(subjinfo,{condlist{c,1},'base'},'latency',timewin{t},'numrand',numrand);
%     %     end
%     
%     load(sprintf('cond_%d_%s-base_%d-%d_gfp.mat',subjinfo,condlist{c,1},timewin{1}(1),timewin{1}(2)));
%     if strcmp(condlist{c,1},'TRG1')
%         clear stats
%         stats(1) = stat;
%         load(sprintf('cond_%d_%s-base_%d-%d_gfp.mat',subjinfo,condlist{c,1},timewin{2}(1),timewin{2}(2)));
%         stats(2) = stat;
%         plotgfp2(stats,'legendstrings',condlist(c,2));
%         
%     else
%         plotgfp(stat,'legendstrings',condlist(c,2),'plotinfo','off');
%     end
%     close(gcf);
% end

for s = 1:length(subjlist)
    basename = subjlist{s};
    fprintf('Processing %s.\n',basename);
        
    %batchres{s,1} = basename;
%     ploterp(basename,{'TRG1','TRG2','DIST'},'ylim',[-7 7]);
%     close all
    
%         dataimport(basename);
%         epochdata(basename,1);
    
%           rejartifacts2([basename '_epochs'],1,4);
    
%             computeic([basename '_epochs']);
    %
%                 rejectic(basename,'prompt','off');
%                 rejartifacts2(basename,2,3,0);
                
%                 mergedata({basename,[basename '_base']});



    for c = 1:size(condlist,1)
        for t = 1:length(timewin)
            compgfp(basename,{condlist{c,1},'base'},'latency',timewin{t},'numrand',numrand);
        end

        load(sprintf('trial_%s_%s-base_%d-%d_gfp.mat',basename,condlist{c,1},timewin{1}(1),timewin{1}(2)));
        stat = corrp(stat);

        if strcmp(condlist{c,1},'TRG1')
            clear stats
            stats(1) = stat;

            load(sprintf('trial_%s_%s-base_%d-%d_gfp.mat',basename,condlist{c,1},timewin{2}(1),timewin{2}(2)));
            stat = corrp(stat);
            
            stats(2) = stat;
            plotgfp2(stats,'legendstrings',condlist(c,2));
        else
            plotgfp(stat,'legendstrings',condlist(c,2),'plotinfo','off');
        end
        close(gcf);
    end
    
%    EEG = pop_loadset('filepath',filepath,'filename',[basename '_orig.set'],'loadmode','info');
%    fprintf('%s :',basename);
%    for e = 1:length(EEG.event)
% %        if strcmp(EEG.event(e).type,'TRG1') && firsttarg
% %            fprintf('block %d num %d ori %d.\n',...
% %                EEG.event(e).codes{strcmp('BNUM',EEG.event(e).codes(:,1)),2},...
% %                EEG.event(e).codes{strcmp('WNUM',EEG.event(e).codes(:,1)),2},...
% %                EEG.event(e).codes{strcmp('WORI',EEG.event(e).codes(:,1)),2});
% %            firsttarg = false;
%        if strcmp(EEG.event(e).type,'BGIN')% || strcmp(EEG.event(e).type,'BEND')
%            fprintf('%d ',EEG.event(e).codes{strcmp('BNUM',EEG.event(e).codes(:,1)),2});
% %            firsttarg = true;
%        end
%    end
%    fprintf('\n');

%    batchres{s,2} = lda(EEG,{'TRG1','DIST'},'stepwise','50:50');
%    batchres{s,3} = lda(EEG,{'TRG2','DIST'},'stepwise','50:50');

%         javaaddpath('/Users/chennu/Work/mffimport/MFF-1.0.d0004.jar');
%         filenames = dir(sprintf('%s%s*', filepath, basename));
%         mfffiles = filenames(logical(cell2mat({filenames.isdir})));
%         filename = mfffiles.name;
%         info = read_mff_subj([filepath filename]);
    
    %    EEG = pop_loadset('filepath',filepath,'filename',[basename '_epochs.set'],'loadmode','info');
    %     prevblocknum = 0;
    %     for e = 1:length(EEG.epoch)
    %         eventcodes = EEG.epoch(e).eventcodes{cell2mat(EEG.epoch(e).eventlatency) == 0};
    %         if ~strcmp(eventcodes{1,1},'BNUM')
    %             error('Unexpected code %s found.',eventcodes{1,1});
    %         end
    %         blocknum = eventcodes{1,2};
    %         if blocknum > 20
    %             fprintf('Deleting after block %d.\n',prevblocknum);
    %             EEG = pop_select(EEG,'trial',1:e-1);
    %             pop_saveset(EEG,'savemode','resave');
    %             break
    %         else
    %             prevblocknum = blocknum;
    %         end
    %     end
    
end

% [~,sortidx] = sort(batchres(:,2));
% batchres(sortidx,:)

%save(sprintf('batch %s.mat',datestr(now)),'batchres');