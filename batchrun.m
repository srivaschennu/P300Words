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
    {'TRG1' 'base'} {'explicit'}
    {'TRG2' 'base'} {'implicit'}
    {'DIST' 'base'} {'distractor'}
%     {'TRG1' 'TRG2'} {'explicit' 'implicit'}
%         {'TRG'  'DIST'} {'explicit' 'distractor'}
%         {'TRG2'  'DIST'} {'implicit' 'distractor'}
%     {'DIST'  'DIST'} {'eccentric' 'central'}
    };

timewin = {
    [100 400]
    [400 700]
    %    [100 700]
    };

% for c = 1:size(condlist,1)
% %             if strcmp(condlist{c,1}{1},'TRG1')
% %                 ploterp(subjinfo,condlist{c,1}(1),'ylim',[-3 3],'topowin',[100 400; 400 700]);
% %             else
% %                 ploterp(subjinfo,condlist{c,1}(1),'ylim',[-3 3],'topowin',[100 400],'plotinfo','off');
% %             end
% %     
%     for t = 1:length(timewin)
% %         compgfp2(subjinfo,condlist{c,1},'latency',timewin{t},'numrand',numrand);
%         load(sprintf('%s/cond_%d_%s-%s_%d-%d_gfp.mat',filepath,subjinfo,condlist{c,1}{1},condlist{c,1}{2},timewin{t}(1),timewin{t}(2)));
% %         stat = corrclust(stat);
% %         save(sprintf('%s/cond_%d_%s-%s_%d-%d_gfp.mat',filepath,subjinfo,condlist{c,1}{1},condlist{c,1}{2},timewin{t}(1),timewin{t}(2)),'stat');
%         stats{t} = stat;
% 
% %         calctct(subjinfo,condlist{c,1}(1),'latency',timewin{t});
% %         load(sprintf('%s/cond_%d_%s_%d-%d_tct.mat',filepath,subjinfo,condlist{c,1}{1},timewin{t}(1),timewin{t}(2)));
% %         stat = corrtct(stat);
% %         save(sprintf('%s/cond_%d_%s_%d-%d_tct.mat',filepath,subjinfo,condlist{c,1}{1},timewin{t}(1),timewin{t}(2)),'stat');
% %         stats{t} = stat;
%     end
% 
%     if strcmp(condlist{c,1}{1},'TRG1')
% %         plotgfp2(stats,'legendstrings',condlist{c,2},'ylim',[-5 20]);
%         plotgfp(stats{1},'legendstrings',condlist{c,2},'plotinfo','on','ylim',[-3 6]);
%     else
%         plotgfp(stats{1},'legendstrings',condlist{c,2},'plotinfo','off','ylim',[-3 6]);
%     end
%     close(gcf);
% end

for s = 1:length(subjlist)
    basename = subjlist{s};
    fprintf('Processing %s.\n',basename);
%     fprintf('%s\n',strtok(basename,'_'));
%     batchres{s,1} = basename;
    
    
    
%                 dataimport(basename);
%                 epochdata(basename,1);
    
%                   rejartifacts2([basename '_epochs'],1,4);
    
%     computeic([basename '_epochs']);
    
    
% rejectic(basename);

%                     rejectic(basename,'prompt','off');
%                     rejartifacts2(basename,2,3);
    
    %                 mergedata({basename,[basename '_base']});
    
%     calcspectra(basename);
%     specinfo = load([basename '_spec.mat']);
%     batchres{s,2} = specinfo.bandpower;
    
    
    
        for c = 1:size(condlist,1)
            if strcmp(condlist{c,1}{1},'TRG1')
                plotparam = {'plotinfo','on'};
            else
                plotparam = {'plotinfo','off'};
            end
%             
%             if strcmp(condlist{c,1}{1},'TRG1')
% % %                 ploterp(basename,condlist{c,1}(1),'ylim',[-4 4],'topowin',[400 700],'caxis',100,plotparam{:});
% %                 ploterp(basename,condlist{c,1}(1),'ylim',[-4 4],'topowin',[100 400],'caxis',75,plotparam{:});
% %             else
% %                 ploterp(basename,condlist{c,1}(1),'ylim',[-4 4],'topowin',[100 400],'caxis',75,plotparam{:});
% %             end
% %             close(gcf);
%             
            for t = 1:length(timewin)
%                 compgfp2(basename,condlist{c,1},'latency',timewin{t},'numrand',numrand);
                load(sprintf('%s/trial_%s_%s-%s_%d-%d_gfp_rmbase.mat',filepath,basename,condlist{c,1}{1},condlist{c,1}{2},timewin{t}(1),timewin{t}(2)));
%                 stat = corrclust(stat);
%                 save(sprintf('%s/trial_%s_%s-%s_%d-%d_gfp_rmbase.mat',filepath,basename,condlist{c,1}{1},condlist{c,1}{2},timewin{t}(1),timewin{t}(2)),'stat');
                stats{t} = stat;

%                 calctct(basename,condlist{c,1}(1),'latency',timewin{t});
%                 load(sprintf('%s/trial_%s_%s_%d-%d_tct.mat',filepath,basename,condlist{c,1}{1},timewin{t}(1),timewin{t}(2)));
%                 stat = corrtct(stat);
%                 save(sprintf('%s/trial_%s_%s_%d-%d_tct.mat',filepath,basename,condlist{c,1}{1},timewin{t}(1),timewin{t}(2)),'stat');
%                 stats{t} = stat;
            end
    
            if strcmp(condlist{c,1}{1},'TRG1')
%                 plotgfp2(stats,'legendstrings',condlist{c,2},plotparam{:},'ylim',[-2 18]);
                plotgfp(stats{1},'legendstrings',condlist{c,2},plotparam{:},'ylim',[-2 18]);
            else
                plotgfp(stats{1},'legendstrings',condlist{c,2},plotparam{:},'ylim',[-2 18]);
            end
            close(gcf);
        end
%     
    %        EEG = pop_loadset('filepath',filepath,'filename',[basename '_orig.set'],'loadmode','info');
    %        fprintf('%s: ',basename);
    %        for e = 1:length(EEG.event)
    %            if strcmp(EEG.event(e).type,'TRG1') && firsttarg
    %                fprintf('%d ',...
    %                    EEG.event(e).codes{strcmp('WNUM',EEG.event(e).codes(:,1)),2});%,...
    %              %      EEG.event(e).codes{strcmp('BNUM',EEG.event(e).codes(:,1)),2},...
    %                    %EEG.event(e).codes{strcmp('WORI',EEG.event(e).codes(:,1)),2});
    %                firsttarg = false;
    %            elseif strcmp(EEG.event(e).type,'BGIN')% || strcmp(EEG.event(e).type,'BEND')
    %                %fprintf('%d ',EEG.event(e).codes{strcmp('BNUM',EEG.event(e).codes(:,1)),2});
    %                firsttarg = true;
    %            end
    %        end
    %        fprintf('\n');
    
    %    batchres{s,2} = lda(EEG,{'TRG1','DIST'},'stepwise','50:50');
    %    batchres{s,3} = lda(EEG,{'TRG2','DIST'},'stepwise','50:50');
    
%                 javaaddpath('/Users/chennu/Work/mffimport/MFF-1.0.d0004.jar');
%                 filenames = dir(sprintf('%s%s*', filepath, basename));
%                 mfffiles = filenames(logical(cell2mat({filenames.isdir})));
%                 filename = mfffiles.name;
%     
%                 fprintf('Reading information from %s%s.\n',filepath,filename);
%                 mffinfo = read_mff_info([filepath filename]);
%                 mffdate = sscanf(mffinfo.date,'%d-%d-%d');
%                 batchres{s,2} = sprintf('%02d/%02d/%04d',mffdate(3),mffdate(2),mffdate(1));
    %
    %             fprintf('Reading subject information from %s%s.\n',filepath,filename);
    %             subjinfo = read_mff_subj([filepath filename])
    
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
    
%         EEG = pop_loadset('filepath',filepath,'filename',[basename '.set'],'loadmode','info');
%         if isfield(EEG,'rejchan')
%             batchres{s,2} = length(EEG.rejchan);
%         else
%             batchres{s,2} = 0;
%         end
%     
%         if isfield(EEG,'rejepoch')
%             batchres{s,3} = length(EEG.rejepoch);
%         else
%             batchres{s,3} = 0;
%         end
%     
%         EEG = pop_loadset('filepath',filepath,'filename',[basename '_epochs.set'],'loadmode','info');
%         batchres{s,4} = sum(EEG.reject.gcompreject);
end

% [~,sortidx] = sort(batchres(:,2));
% batchres(sortidx,:)
%
% save(sprintf('batch %s.mat',datestr(now)),'batchres');