function p300words(paramfile)

global hd

if isstruct(hd) && exist('paramfile','var')
    error('Pre-existing block information found! Do not specify a parameter file.');
elseif isempty(hd)
    if nargin == 0 || ~exist('paramfile','var')
        paramfile = 'param_patient.mat';
    end
    %randomly permute order of words (except practice word), using a clock-based random number seed
    RandStream.setDefaultStream(RandStream('mt19937ar','seed',sum(100*clock)));
end

if ~isfield(hd,'datafile')
    ts = fix(clock);
    datetimestr = sprintf('%02d-%02d-%04d %02d-%02d-%02d',ts(3),ts(2),ts(1),ts(4),ts(5),ts(6));
    
    if ispc
        datapath = 'data\';
    elseif ismac
        datapath = 'data/';
    end
    
    if ~exist(datapath,'dir')
        mkdir(datapath)
    end
    hd.datafile = sprintf('%s %s.mat',datapath,datetimestr);
    
    diaryfile = sprintf('%s %s.txt',datapath,datetimestr);
    diary(diaryfile);
end

diary on

hd.paramfile = paramfile;
fprintf('Loading parameters from %s.\n',hd.paramfile);
load(hd.paramfile);

hd.presmode = presmode;
hd.numblocks = numblocks;
hd.groupsize = groupsize;
hd.ontime = ontime;
hd.ontimejitter = ontimejitter;
hd.offtime = offtime;
hd.trepint = trepint;
hd.trepintjitter = trepintjitter;
hd.runcountbase = runcountbase;
hd.runcountrange = runcountrange;
hd.validresp = validresp;
hd.instrmode = instrmode;
if hd.instrmode > 0
    hd.questions = questions(1:hd.instrmode);
end

hd.ontime = ontime/1000;
hd.offtime = offtime/1000;
hd.ontimejitter = ontimejitter/1000;
hd.numori = 9;
hd.orilist = 1:hd.numori;
hd.orideg = round(linspace(-90,90,hd.numori));
hd.orilag = -40:10:40;
hd.prefixwait = 6;
hd.fixcrosstime = 5;
hd.postfixwait = 2;
hd.runwaittime = 0.0;

fprintf('\nUsing ON time of %.3f seconds with OFF time of %.3f seconds.\n', hd.ontime, hd.offtime);

if ~isfield(hd,'nsstatus') && ...
        exist('nshost','var') && ~isempty(nshost) && ...
        exist('nsport','var') && nsport ~= 0
    fprintf('Connecting to Net Station.\n');
    [nsstatus, nserror] = NetStation('Connect',nshost,nsport);
    if nsstatus ~= 0
        error('Could not connect to NetStation host %s:%d.\n%s\n', ...
            nshost, nsport, nserror);
    end
    hd.nsstatus = nsstatus;
end
NetStation('Synchronize');
pause(1);

%connect to srbox
%srboxport = '/dev/cu.PL2303-0000101D';
if ~isfield(hd,'srboxporth')
    if exist('srboxport','var') && ~isempty(srboxport)
        fprintf('Connecting to srbox port %s.\n', srboxport);
        hd.srboxporth = CMUBox('Open', 'pst', srboxport, 'norelease');
        if hd.srboxporth == 0
            error('Could not open srbox port %s.\n', srboxport);
        end
    else
        hd.srboxporth = 0;
    end
end

%init psychtoolbox sound
if ~isfield(hd,'pahandle')
    hd.f_sample = 44100;
    fprintf('Initialising audio.\n');
    
    InitializePsychSound
    
    if PsychPortAudio('GetOpenDeviceCount') == 1
        PsychPortAudio('Close',0);
    end
    
    %Mac
    if ismac
        audiodevices = PsychPortAudio('GetDevices');
        outdevice = strcmp('Built-in Output',{audiodevices.DeviceName});
        hd.outdevice = 1;
    elseif ispc
        %DMX
        % audiodevices = PsychPortAudio('GetDevices',3);
        % outdevice = strcmp('DMX 6Fire USB ASIO Driver',{audiodevices.DeviceName});
        % hd.outdevice = 2;
        
        %Windows
        audiodevices = PsychPortAudio('GetDevices',2);
        outdevice = strcmp('Microsoft Sound Mapper - Output',{audiodevices.DeviceName});
        hd.outdevice = 3;
    else
        error('Unsupported OS platform!');
    end
    
    hd.pahandle = PsychPortAudio('Open',audiodevices(outdevice).DeviceIndex,[],[],hd.f_sample,2);
end

%load audio
if ~isfield(hd,'wordaudio')
    fprintf('Loading audio...\n');

    hd.audiodir = 'Stimuli';
    
    snddata = maketone(hd.f_sample,800,0.1)';
    hd.shortbeep = repmat(snddata,2,1);
        
    snddata = maketone(hd.f_sample,800,0.5)';
    hd.longbeep = repmat(snddata,2,1);
    
    %list of words to spell
    hd.wordlist = importdata([hd.audiodir '/wordlist.txt']);
    maxlen = 0;
    maxid = 0;
    for i = 1:size(hd.wordlist,1)
        snddata = wavread(sprintf('%s/%s',hd.audiodir,lower(hd.wordlist{i})))';
        hd.wordaudio{i} = repmat(snddata,2,1);
        if size(snddata,2)*1000/hd.f_sample > maxlen
            maxid = i;
            maxlen = size(snddata,2)*1000/hd.f_sample;
        end
    end
    %fprintf('Longest word is %s at %dms.\n', hd.wordlist{maxid}, round(maxlen));
end

if ~isfield(hd,'targwords')
    hd.blocknum = 1;
    
    if hd.instrmode == 0
        hd.instrorder = zeros(1,hd.numblocks);
        
        %NOTE: YES and NO target words assumed to be first two in wordlist
        hd.targwords = zeros(hd.numblocks,2);
        hd.targwords(1:round(hd.numblocks/2),1) = 1;
        hd.targwords(1:round(hd.numblocks/2),2) = 2;
        hd.targwords(round(hd.numblocks/2)+1:end,1) = 2;
        hd.targwords(round(hd.numblocks/2)+1:end,2) = 1;
        
        if hd.numblocks == 1
            blockorder = 1;
        else
            grouporder = 1:hd.groupsize:hd.numblocks;
            grouporder = grouporder(randperm(length(grouporder)));
            blockorder = grouporder;
            for g = 1:hd.groupsize-1
                blockorder = cat(1,blockorder,grouporder+g);
            end
            blockorder = blockorder(:);
        end
        hd.targwords = hd.targwords(blockorder,:);
        
        if hd.presmode == 1
            hd.targori = repmat(find(hd.orideg == 0),hd.numblocks,2);
            hd.distori = repmat(find(hd.orideg == 0),1,length(hd.orilist));
        elseif hd.presmode == 2
            hd.targori = zeros(hd.numblocks,2);
            hd.targori(1:round(hd.numblocks/2),1) = hd.orilist(1);
            hd.targori(1:round(hd.numblocks/2),2) = hd.orilist(end);
            hd.targori(round(hd.numblocks/2)+1:end,1) = hd.orilist(end);
            hd.targori(round(hd.numblocks/2)+1:end,2) = hd.orilist(1);
            hd.targori = hd.targori(blockorder,:);
            hd.distori = hd.orilist(2:end-1);
        end
        
    elseif hd.instrmode > 0
        hd.instrorder = repmat(1:hd.instrmode,1,2);
        %hd.instrorder = hd.instrorder(randperm(length(hd.instrorder)));
        hd.numblocks = length(hd.instrorder);
        hd.targwords = zeros(hd.numblocks,2);
        hd.targwords(:,1) = 1;
        hd.targwords(:,2) = 2;
        
        if hd.presmode == 1
            hd.targori = repmat(find(hd.orideg == 0),hd.numblocks,2);
            hd.distori = repmat(find(hd.orideg == 0),1,length(hd.orilist));
        elseif hd.presmode == 2
            hd.targori = zeros(hd.numblocks,2);
            hd.targori(:,1) = hd.orilist(1);
            hd.targori(:,2) = hd.orilist(end);
            hd.distori = hd.orilist(2:end-1);
        end
    end
    
    hd.distwords = 3:size(hd.wordlist,1);
end

if ~isfield(hd,'stimdata')
    hd.stimdata = {};
    hd.respdata = zeros(1,hd.numblocks);
end

%% main block loop
while hd.blocknum <= hd.numblocks
    hd.tStart = tic;
    
    setupblock;
    
    %     fprintf('\nPress ENTER to continue or CTRL-C to quit.\n');
    %
    %     kbinput = GetChennu(true);
    %     while ~(ischar(kbinput) && strcmpi(kbinput,'return'))
    %         kbinput = GetChennu(true);
    %     end
    
    %start recording
    NetStation('StartRecording');
    pause(1);
    
    %send begin marker
    NetStation('Event','BGIN',GetSecs,0.001,'BNUM',hd.blocknum,'PMOD',hd.presmode);
    
    %Priority(MaxPriority(0));
    Priority(0);
    
    hd.events(2,:) = hd.events(2,:) + GetSecs;
    hd.curevent = 1;
    
    while true
        curtime = GetSecs;
        if hd.curevent <= size(hd.events,2) && hd.events(2,hd.curevent)-curtime <= 0
            switch hd.events(1,hd.curevent)
                
                case 0
                    PsychPortAudio('Stop', hd.pahandle);
                    
                case -1 %show fix cross
                    PsychPortAudio('FillBuffer',hd.pahandle, cat(2, hd.shortbeep, hd.instraudio));
                    startTime = PsychPortAudio('Start',hd.pahandle,1,0,1);
                    if hd.outdevice == 3
                        startTime = GetSecs;
                    end
                    NetStation('Event','INST',startTime,0.001,'BNUM',hd.blocknum,'IMOD',hd.instrmode,'INUM',hd.instrorder(hd.blocknum));
                    
                otherwise %show item
                    waudio = hd.wordaudio{hd.events(1,hd.curevent)};
                    wori = hd.events(3,hd.curevent);

                    %waudio = cat(1, waudio(1,:)*((hd.numori-wori)/(hd.numori-1)), waudio(2,:)*((wori-1)/(hd.numori-1)));
                    if hd.orilag(wori) > 0
                        waudio = cat(1, cat(2,zeros(1,hd.orilag(wori)),waudio(1,1:end-hd.orilag(wori))), waudio(2,:));
                    elseif hd.orilag(wori) < 0
                        waudio = cat(1, waudio(1,:), cat(2,zeros(1,-hd.orilag(wori)),waudio(2,1:end+hd.orilag(wori))));
                    end

                    PsychPortAudio('FillBuffer',hd.pahandle,waudio);
                    startTime = PsychPortAudio('Start',hd.pahandle,1,0,1);
                    if hd.outdevice == 3
                        startTime = GetSecs;
                    end
                    setClearTrigger(startTime,hd.events(1,hd.curevent),hd.events(3,hd.curevent));
                    hd.times = [hd.times (startTime-hd.events(2,hd.curevent))];
            end

            %Wait till sound stops playing... ensures better playback on
            %Windows
            PsychPortAudio('Stop',hd.pahandle,1);
            
            hd.curevent = hd.curevent + 1;

        elseif hd.curevent > size(hd.events,2)
            break;
        end
    end
    
    Priority(0);
    %play question beep here
    PsychPortAudio('FillBuffer',hd.pahandle,hd.longbeep);
    stopTime = PsychPortAudio('Start',hd.pahandle,1,0,1);
    if hd.outdevice == 3
        stopTime = GetSecs;
    end
    NetStation('Event','STOP',stopTime,0.001,'BNUM',hd.blocknum);
    
    if hd.srboxporth ~= 0
        clearsrbox
        %wait for input
        srboxevent = CMUBox('GetEvent', hd.srboxporth,1);
        %send response marker and store response
        if ~isempty(srboxevent)
            if sum(srboxevent.state == hd.validresp) == 1
                thisresp = length(dec2bin(srboxevent.state));
                hd.respdata(hd.blocknum) = hd.runcountbase-1+thisresp;
                NetStation('Event','BTNP',GetSecs,0.001,'RESP',thisresp,'VALU',hd.respdata(hd.blocknum));
                fprintf('Button %d (%d) pressed. ', thisresp, hd.respdata(hd.blocknum));
                if hd.respdata(hd.blocknum) == hd.runcount
                    fprintf('CORRECT\n');
                else
                    fprintf('INCORRECT\n');
                end
            else
                fprintf('Invalid response code %d.\n', srboxevent.state);
                NetStation('Event','BTNP',GetSecs,0.001,'RESP', srboxevent.state);
            end
        end
    end
    
    fprintf('Block %d took %.1f min. start delay mean = %.1fms, std = %.1fms.\n', hd.blocknum, toc(hd.tStart)/60, mean(hd.times)*1000, std(hd.times,1)*1000);
    NetStation('Event','BEND',GetSecs,0.001,'BNUM',hd.blocknum);
    pause(1);
    
    fprintf('Saving block data.\n');
    hd.stimdata = cat(1, hd.stimdata, {cat(1,hd.wordseq,hd.wordori)});
    save(hd.datafile, '-struct', 'hd', 'targwords', 'targori', 'stimdata', 'respdata');
    
    hd.blocknum = hd.blocknum+1;
    
    if rem(hd.blocknum-1,hd.numblocks/2) == 0
        NetStation('StopRecording');
    end
    if pausefor(10)
        break
    end
end

%exit nicely

NetStation('StopRecording');

if hd.blocknum > hd.numblocks
    PsychPortAudio('Close',hd.pahandle);
    if hd.srboxporth ~= 0
        %close srbox port
        CMUBox('Close', hd.srboxporth);
    end
    clear global hd
    fprintf('DONE!\n');
end

diary off
end

%% setupblock
function setupblock
global hd

fprintf('\nSetting up block %d...\n',hd.blocknum);

hd.run = false;
hd.stop = false;

hd.runcount = hd.runcountbase+round(rand*hd.runcountrange);

if hd.instrmode == 0
    fprintf('Instruction is COUNT.\n');
    snddata = wavread(sprintf('%s/count.wav',hd.audiodir))';
    hd.instraudio = repmat(snddata,2,1);
    
    waudio = hd.wordaudio{hd.targwords(hd.blocknum,1)};
    wori = hd.targori(hd.blocknum,1);

    %waudio = cat(1, waudio(1,:)*((hd.numori-wori)/(hd.numori-1)), waudio(2,:)*((wori-1)/(hd.numori-1)));
    if hd.orilag(wori) > 0
        waudio = cat(1, cat(2,zeros(1,hd.orilag(wori)),waudio(1,1:end-hd.orilag(wori))), waudio(2,:));
    elseif hd.orilag(wori) < 0
        waudio = cat(1, waudio(1,:), cat(2,zeros(1,-hd.orilag(wori)),waudio(2,1:end+hd.orilag(wori))));
    end
    
    hd.instraudio = cat(2, hd.instraudio, waudio);
else
    fprintf('Instruction is %s.\n',hd.questions{hd.instrorder(hd.blocknum)});
    qaudio = wavread(sprintf('%s/%s.wav',hd.audiodir,hd.questions{hd.instrorder(hd.blocknum)}))';
    caudio = wavread(sprintf('%s/countq.wav',hd.audiodir))';
    ynaudio = wavread(sprintf('%s/yesorno.wav',hd.audiodir))';
    snddata = cat(2, qaudio, caudio, qaudio, ynaudio);
    hd.instraudio = repmat(snddata,2,1);
    hd.fixcrosstime = 12;
end

firsttargpos = zeros(1,hd.runcount);
prevfirsttargpos = 0;
for targ = 1:hd.runcount
    firsttargpos(targ) = prevfirsttargpos + hd.trepint+round(rand*hd.trepintjitter*2)-hd.trepintjitter;
    prevfirsttargpos = firsttargpos(targ);
end

secondtargpos = zeros(1,hd.runcount);
prevsecondtargpos = 0;
for targ = 1:hd.runcount
    secondtargpos(targ) = prevsecondtargpos + hd.trepint+round(rand*hd.trepintjitter*2)-hd.trepintjitter;
    while sum(secondtargpos(targ) == firsttargpos) > 0
        secondtargpos(targ) = prevsecondtargpos + hd.trepint+round(rand*hd.trepintjitter*2)-hd.trepintjitter;
    end
    prevsecondtargpos = secondtargpos(targ);
end

if ~isempty(intersect(firsttargpos,secondtargpos))
    fprintf('\n');
    fprintf('firsttargpos = %s\n',num2str(firsttargpos));
    fprintf('secondtargpos = %s\n',num2str(secondtargpos));
    error('Target positions allocation error!');
end

hd.wordseq = [];
hd.wordseq(firsttargpos) = hd.targwords(hd.blocknum,1);
hd.wordseq(secondtargpos) = hd.targwords(hd.blocknum,2);
hd.wordseq = [hd.wordseq zeros(1,hd.trepint)];

distpos = find(hd.wordseq == 0);
while ~isempty(distpos)
    numdwords = min(length(distpos),length(hd.distwords));
    while true
        hd.wordseq(distpos(1:numdwords)) = randsample(hd.distwords,numdwords);
        if distpos(1) < 2 || hd.wordseq(distpos(1)-1) ~= hd.wordseq(distpos(1))
            break;
        end
    end
    distpos = find(hd.wordseq == 0);
end

hd.wordori = zeros(size(hd.wordseq));
hd.wordori(firsttargpos) = hd.targori(hd.blocknum,1);
hd.wordori(secondtargpos) = hd.targori(hd.blocknum,2);

distpos = find(hd.wordori == 0);
while ~isempty(distpos)
    numdori = min(length(distpos),length(hd.distori));
    hd.wordori(distpos(1:numdori)) = randsample(hd.distori,numdori);
    distpos = find(hd.wordori == 0);
end

hd.times = [];

%prepare event list
hd.events = [];
nextevent = 1;

%fix cross on
hd.events(1,nextevent) = -1;
hd.events(2,nextevent) = hd.prefixwait;
nextevent = nextevent+1;
nexttime = hd.events(2,1) + hd.fixcrosstime;

%fix cross off
hd.events(1,nextevent) = 0;
hd.events(2,nextevent) = nexttime;
nextevent = nextevent+1;
nexttime = nexttime + hd.postfixwait;

for k = 1:length(hd.wordseq)
    %item on
    hd.events(1,nextevent) = hd.wordseq(k);
    hd.events(2,nextevent) = nexttime;
    hd.events(3,nextevent) = hd.wordori(k);
    nextevent = nextevent+1;
    nexttime = nexttime + hd.ontime+(rand*hd.ontimejitter*2)-hd.ontimejitter;
    
    %item off
    hd.events(1,nextevent) = 0;
    hd.events(2,nextevent) = nexttime;
    nextevent = nextevent+1;
    nexttime = nexttime + hd.offtime;
end

%final placeholder event
hd.events(1,nextevent) = 0;
hd.events(2,nextevent) = nexttime;

fprintf('\nBlock %d of %d (mode %d): Target 1 is %s (%ddeg), Target 2 is %s (%ddeg),\n each repeated %d times over %d words (%d%% probability).\n', ...
    hd.blocknum, hd.numblocks, hd.presmode, upper(hd.wordlist{hd.targwords(hd.blocknum,1)}), hd.orideg(hd.targori(hd.blocknum,1)), ...
    upper(hd.wordlist{hd.targwords(hd.blocknum,2)}), hd.orideg(hd.targori(hd.blocknum,2)), hd.runcount, length(hd.wordseq), round(hd.runcount*100/length(hd.wordseq)));

end


%% setClearTrigger
function setClearTrigger(t,wordnum,wordori)
global hd

if wordnum ~= 0
    if wordnum == hd.targwords(hd.blocknum,1)
        NetStation('Event','TRG1',t,0.001,'BNUM',hd.blocknum,'WNUM',wordnum,'WORI',wordori,'INUM',hd.instrorder(hd.blocknum));
    elseif wordnum == hd.targwords(hd.blocknum,2)
        NetStation('Event','TRG2',t,0.001,'BNUM',hd.blocknum,'WNUM',wordnum,'WORI',wordori,'INUM',hd.instrorder(hd.blocknum));
    else
        NetStation('Event','DIST',t,0.001,'BNUM',hd.blocknum,'WNUM',wordnum,'WORI',wordori,'INUM',hd.instrorder(hd.blocknum));
    end
end
end


%% clearinputs
function clearsrbox
global hd

%clear any inputs from srbox
if hd.srboxporth ~= 0
    while true
        srboxevent = CMUBox('GetEvent', hd.srboxporth);
        if isempty(srboxevent)
            break;
        end
    end
end
end