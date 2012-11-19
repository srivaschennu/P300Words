function result = lda(EEG,condlist,clsfyrtype,clsfyrmode,varargin)

%condlist = {'TRG1','TRG2','DIST'};
%condlist = {'TRG1','TRG2'};
condlist = {'TRG1','DIST'};
numcond = size(condlist,2);

conddata = cell(1,numcond);

s = 1;
for c = 1:numcond
    selectevents = condlist{c};
    selectsnum = 3;
    %selectpred = 1;
    
    typematches = false(1,length(EEG.epoch));
    snummatches = false(1,length(EEG.epoch));
    predmatches = false(1,length(EEG.epoch));
    for ep = 1:length(EEG.epoch)
        
        epochtype = EEG.epoch(ep).eventtype;
        if iscell(epochtype)
            epochtype = epochtype{cell2mat(EEG.epoch(ep).eventlatency) == 0};
        end
        if sum(strcmp(epochtype,selectevents)) > 0
            typematches(ep) = true;
        end
        
        epochcodes = EEG.epoch(ep).eventcodes;
        if iscell(epochcodes{1,1})
            epochcodes = epochcodes{cell2mat(EEG.epoch(ep).eventlatency) == 0};
        end
        
        snumidx = strcmp('SNUM',epochcodes(:,1)');
        if exist('selectsnum','var') && ~isempty(selectsnum) && sum(snumidx) > 0
            if sum(epochcodes{snumidx,2} == selectsnum) > 0
                snummatches(ep) = true;
            end
        else
            snummatches(ep) = true;
        end
        
        predidx = strcmp('PRED',epochcodes(:,1)');
        if exist('selectpred','var') && ~isempty(selectpred) && sum(predidx) > 0
            if sum(epochcodes{predidx,2} == selectpred) > 0
                predmatches(ep) = true;
            end
        else
            predmatches(ep) = true;
        end
    end
    
    selectepochs = find(typematches & snummatches & predmatches);
    fprintf('Condition %s: found %d matching epochs.\n',condlist{c},length(selectepochs));
    conddata{s,c} = pop_select(EEG,'trial',selectepochs);
    
    %     if conddata{s,1}.trials > conddata{s,2}.trials
    %         fprintf('Equalising trials in condition %s.\n',condlist{s,1});
    %         randtrials = randperm(conddata{s,1}.trials);
    %         conddata{s,1} = pop_select(conddata{s,1},'trial',randtrials(1:conddata{s,2}.trials));
    %     elseif conddata{s,2}.trials > conddata{s,1}.trials
    %         fprintf('Equalising trials in condition %s.\n',condlist{s,2});
    %         randtrials = randperm(conddata{s,2}.trials);
    %         conddata{s,2} = pop_select(conddata{s,2},'trial',randtrials(1:conddata{s,1}.trials));
    %     end
end

EEG = pop_mergeset(conddata{s,1},conddata{s,2});

%trainchan = {'E11' 'E24'  'E62'   'E65'   'E75'   'E90'  'E124' 'Cz'};
trainchan = {EEG.chanlocs.labels};
for t = 1:length(trainchan)
    trainchan{t} = find(strcmp(trainchan{t},{EEG.chanlocs.labels}));
end
trainchan = cell2mat(trainchan);

dsfactor = 5;
trainwin = [0 700];
trainwin = find(EEG.times <= trainwin(1),1,'last'):find(EEG.times >= trainwin(2),1,'first');

fprintf('Extracting features from %s.\n',EEG.setname);
data = reshape(permute(EEG.data(trainchan,trainwin,:), [3 2 1]), EEG.trials, length(trainchan)*length(trainwin));
features = zeros(EEG.trials,length(trainchan)*length(trainwin));
labels = zeros(EEG.trials,1);
trialtypes = cell(EEG.trials,1);
trialbnums = zeros(EEG.trials,1);

for t = 1:EEG.trials
    epochidx = find(cell2mat(EEG.epoch(1,t).eventlatency) == 0);
    trialtype = EEG.epoch(1,t).eventtype{epochidx};
    
    features(t,:) = data(t,:);
    trialtypes{t} = trialtype;
    bnumidx = strcmp('BNUM',EEG.epoch(1,t).eventcodes{epochidx}(:,1));
    trialbnums(t) = EEG.epoch(1,t).eventcodes{epochidx}{bnumidx,2};
    
    if strcmp(condlist{1},trialtype)
        labels(t) = 1;
    elseif strcmp(condlist{2},trialtype)
        labels(t) = 0;
    else
        error('Unknown trial type: %s',trialtype);
    end
end

features = double(downsample(features',dsfactor)');

switch clsfyrmode
    
    case '50:50'
        numfeatures = size(features,2);
        
        uniqblocks = unique(trialbnums);
        traintrials = find(ismember(trialbnums,uniqblocks(1:round(length(uniqblocks)/2))));
        testtrials = find(ismember(trialbnums,uniqblocks(round(length(uniqblocks)/2):end)));
        
        class1trials = find(labels == 1);
        class0trials = find(labels == 0);
        class1trials = intersect(class1trials,traintrials);
        class0trials = intersect(class0trials,traintrials);
        
        if length(class1trials) > length(class0trials)
            randtrials = randperm(length(class1trials));
            class1trials = class1trials(randtrials(1:length(class0trials)));
        elseif length(class0trials) > length(class1trials)
            randtrials = randperm(length(class0trials));
            class0trials = class0trials(randtrials(1:length(class1trials)));
        end
        traintrials = union(class1trials,class0trials);
        
        fprintf('50:50 train-test over %d (%d+%d) trials with %d features.\n', ...
            length(traintrials)+length(testtrials), length(traintrials), length(testtrials), numfeatures);
        
        trainfeatures = features(traintrials,:);
        trainlabels = labels(traintrials,:);
        testfeatures = features(testtrials,:);
        testlabels = labels(testtrials,:);
        maxfeatures = round(length(testtrials)/10);
        
%         trainfmean = mean(trainfeatures,1);
%         trainfstd = std(trainfeatures,0,1);
%         for f = 1:size(features,2)
%             trainfeatures(:,f) = (trainfeatures(:,f) - trainfmean(f))/trainfstd(f);
%             testfeatures(:,f) = (testfeatures(:,f) - trainfmean(f))/trainfstd(f);
%         end
        
        switch clsfyrtype
            case 'stepwise'
                chancelevel = 0.5;
                trainlabels(trainlabels == 0) = -1;
                testlabels(testlabels == 0) = -1;
                
                [trainweights,~,pval,inmodel] = stepwisefit(trainfeatures,trainlabels,'display','off');
                [~, sortidx] = sort(pval);
                keepfeatures = intersect(sortidx(1:maxfeatures),find(inmodel));
                fprintf('stepwisefit: keeping %d features\n', length(keepfeatures));
                trainresults = trainfeatures(:,keepfeatures) * trainweights(keepfeatures);
                testresults = testfeatures(:,keepfeatures) * trainweights(keepfeatures);

                trainlabels(trainlabels == -1) = 0;
                testlabels(testlabels == -1) = 0;
                
            case 'logistic'
                chancelevel = 0.5;
                %trainweights = glmfit(trainfeatures,trainlabels,'binomial','link','logit');
                %testresults(cvfolds(f):cvfolds(f+1)-1) = glmval(trainweights,testfeatures,'logit');
                trainweights = sbmlr(trainfeatures,cat(2,trainlabels,~trainlabels));
                res = exp(testfeatures*trainweights);
                res = res ./ repmat(sum(res,2),1,size(res,2));
                testresults = res(:,1);
                
            case 'naivebayes'
                chancelevel = 0.5;
                trainweights = NaiveBayes.fit(trainfeatures,trainlabels);
                trainresults = posterior(trainweights,trainfeatures);
                trainresults = trainresults(:,1);
                testresults = posterior(trainweights,testfeatures);
                testresults = testresults(:,1);
%                 trainresults = classify(trainfeatures,trainfeatures,trainlabels,'diaglinear');
%                 testresults = classify(testfeatures,trainfeatures,trainlabels,'diaglinear');
                
            case 'svm'
                chancelevel = 0.5;
                trainweights = svmtrain(trainfeatures,trainlabels);
                trainresults = svmclassify(trainweights,trainfeatures);
                testresults = svmclassify(trainweights,testfeatures);
        end
        [~,rocdata] = evalc('rocanalysis([trainresults trainlabels])');
        close all
        hidx = (testresults(testlabels > chancelevel) > rocdata.co);
        hrate = (sum(hidx)+1)/(length(hidx)+2);
        faidx = (testresults(testlabels < chancelevel) > rocdata.co);
        farate = (sum(faidx)+1)/(length(faidx)+2);
        dprime = norminv(hrate) - norminv(farate);
        [testaccu, testaccuci] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx));
        testaccu = testaccu * 100; testaccuci = testaccuci * 100;
        
        result.testresults = testresults;
        result.testlabels = testlabels;
        result.testaccu = testaccu;
        result.testaccuci = testaccuci;
        result.dprime = dprime;
        result.criterion = rocdata.co;
        result.hitrate = hrate;
        result.farate = farate;
        
    case 'cv'
        for f = 1:size(features,2)
            features(:,f) = (features(:,f) - fmean(f))/fstd(f);
        end
        
        numfolds = 5;
        numtrials = size(features,1);
        numfeatures = size(features,2);
        
        class1trials = find(labels == 1);
        class1trials = class1trials(randperm(length(class1trials)));
        class1folds = round(linspace(1,length(class1trials)+1,numfolds+1));
        
        class0trials = find(labels == 0);
        class0trials = class0trials(randperm(length(class0trials)));
        class0folds = round(linspace(1,length(class0trials)+1,numfolds+1));
        
        cvtrials = 1;
        cvresults = zeros(numtrials,1);
        cvlabels = zeros(numtrials,1);
        
        fprintf('%d-fold CV over %d (%d+%d) trials with %d features: fold %02d', ...
            numfolds, numtrials, length(class1trials), length(class0trials), numfeatures, 0);
        
        for f = 1:numfolds
            fprintf('\b\b%02d',f);
            
            testfeatures = features(cat(1,class1trials(class1folds(f):class1folds(f+1)-1),...
                class0trials(class0folds(f):class0folds(f+1)-1)),:);
            testlabels = labels(cat(1,class1trials(class1folds(f):class1folds(f+1)-1),...
                class0trials(class0folds(f):class0folds(f+1)-1)),:);
            
            trainfeatures = features(cat(1,setdiff(1:length(class1trials),class1trials(class1folds(f):class1folds(f+1)-1))',...
                setdiff(1:length(class0trials),class0trials(class0folds(f):class0folds(f+1)-1))'),:);
            trainlabels = labels(cat(1,setdiff(1:length(class1trials),class1trials(class1folds(f):class1folds(f+1)-1))',...
                setdiff(1:length(class0trials),class0trials(class0folds(f):class0folds(f+1)-1))'),:);
            
            cvlabels(cvtrials:cvtrials+size(testfeatures,1)-1) = testlabels;
            
            switch clsfyrtype
                case 'stepwise'
                    trainlabels(trainlabels == 1) = 1;
                    trainlabels(trainlabels == 0) = -1;
                    testlabels(testlabels == 1) = 1;
                    testlabels(testlabels == 0) = -1;
                    chancelevel = 0;
                    
                    [trainweights,~,~,keepfeatures] = stepwisefit(trainfeatures,trainlabels,'display','off');
                    %fprintf('stepwisefit: keeping %d features\n', sum(keepfeatures));
                    cvresults(cvtrials:cvtrials+size(testfeatures,1)-1) = testfeatures(:,keepfeatures) * trainweights(keepfeatures);
                    
                case 'logistic'
                    chancelevel = 0.5;
                    %trainweights = glmfit(trainfeatures,trainlabels,'binomial','link','logit');
                    %testresults(cvfolds(f):cvfolds(f+1)-1) = glmval(trainweights,testfeatures,'logit');
                    trainweights = sbmlr(trainfeatures,cat(2,trainlabels,~trainlabels));
                    res = exp(testfeatures*trainweights);
                    res = res ./ repmat(sum(res,2),1,size(res,2));
                    cvresults(cvtrials(cvfolds(f):cvfolds(f+1)-1)) = res(:,1);
                    
                case 'naivebayes'
                    chancelevel = 0.5;
                    %                     trainweights = NaiveBayes.fit(trainfeatures,trainlabels);
                    %                     cvresults(cvfolds(f):cvfolds(f+1)-1) = predict(trainweights,testfeatures);
                    cvresults(cvtrials(cvfolds(f):cvfolds(f+1)-1)) = classify(testfeatures,trainfeatures,trainlabels,'diaglinear');
                    
                case 'svm'
                    chancelevel = 0.5;
                    trainweights = svmtrain(trainfeatures,trainlabels);
                    cvresults(cvtrials(cvfolds(f):cvfolds(f+1)-1)) = svmclassify(trainweights,testfeatures);
                    
            end
            cvtrials = cvtrials + size(testfeatures,1);
        end
        fprintf('\n');
        
        rocdata = rocanalysis([cvresults cvlabels]);
        hidx = (cvresults(cvlabels > chancelevel) > rocdata.co);
        hrate = (sum(hidx)+1)/(length(hidx)+2);
        faidx = (cvresults(cvlabels < chancelevel) > rocdata.co);
        farate = (sum(faidx)+1)/(length(faidx)+2);
        dprime = norminv(hrate) - norminv(farate);
        [cvaccu cvaccuci] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx));
        cvaccu = cvaccu * 100; cvaccuci = cvaccuci * 100;
        
        result.cvresults = cvresults;
        result.cvlabels = cvlabels;
        result.cvaccu = cvaccu;
        result.cvaccuci = cvaccuci;
        result.dprime = dprime;
        result.criterion = rocdata.co;
        result.hitrate = hrate;
        result.farate = farate;
        
    case 'train'
        for f = 1:size(features,2)
            features(:,f) = (features(:,f) - fmean(f))/fstd(f);
        end
        
        fprintf('Training with %d observations of %d features.\n', size(features,1), size(features,2));
        
        switch clsfyrtype
            case 'stepwise'
                labels(labels == 1) = 1;
                labels(labels == 0) = -1;
                chancelevel = 0;
                
                [trainweights,~,~,keepfeatures] = stepwisefit(features,labels,'display','off');
                fprintf('stepwisefit: keeping %d features\n', sum(keepfeatures));
                result.keepfeatures = keepfeatures;
                trainresults = features(:,keepfeatures) * trainweights(keepfeatures);
                labels(labels == -1) = 0;
                
            case 'logistic'
                %trainweights = glmfit(features,labels,'binomial','link','logit');
                trainweights = sbmlr(features,cat(2,labels,~labels));
                fprintf('sparse logistic: keeping %d features\n', sum(trainweights(:)~=0));
                
            case 'naivebayes'
                trainweights = NaiveBayes.fit(features,labels);
                
            case 'svm'
                trainweights = svmtrain(features,labels);
        end
        
        
        rocdata = rocanalysis([trainresults labels]);
        hidx = (trainresults(labels > chancelevel) > rocdata.co);
        hrate = (sum(hidx)+1)/(length(hidx)+2);
        faidx = (trainresults(labels < chancelevel) > rocdata.co);
        farate = (sum(faidx)+1)/(length(faidx)+2);
        dprime = norminv(hrate) - norminv(farate);
        [trainaccu trainaccuci] = binofit(sum(hidx)+sum(~faidx),length(hidx)+length(faidx));
        trainaccu = trainaccu * 100; trainaccuci = trainaccuci * 100;
        
        result.trainweights = trainweights;
        result.fmean = fmean;
        result.fstd = fstd;
        result.trainaccu = trainaccu;
        result.trainaccuci = trainaccuci;
        result.dprime = dprime;
        result.criterion = rocdata.co;
        result.hitrate = hrate;
        result.farate = farate;
        
    case 'test'
        traininfo = varargin{1};
        
        for f = 1:size(features,2)
            features(:,f) = (features(:,f) - traininfo.fmean(f))/traininfo.fstd(f);
        end
        
        numblocks = max(unique(trialbnums));
        numinst = max(unique(trialinsts));
        
        fprintf('Testing with %d observations of %d features.\n', size(features,1), size(features,2));
        
        switch clsfyrtype
            case 'stepwise'
                testresults = features(:,traininfo.keepfeatures) * traininfo.trainweights(traininfo.keepfeatures);
                testresults = testresults > traininfo.criterion;
                
            case 'logistic'
                %testresults = glmval(traininfo.trainweights,features,'logit');
                res = exp(features*traininfo.trainweights);
                res = res ./ repmat(sum(res,2),1,size(res,2));
                testresults = res(:,1);
                
            case 'naivebayes'
                testresults = predict(traininfo.trainweights,features);
            case 'svm'
                testresults = svmclassify(traininfo.trainweights,features);
        end
        
        trgest = zeros(numblocks,2);
        trgestci = zeros(numblocks,2,2);
        
        for b = 1:numinst
            for t = 1:2
                switch clsfyrtype
                    %                     case 'stepwise'
                    %                         trgres = testresults((trialbnums == b) & strcmp(sprintf('TRG%d',t),trialtypes));
                    %                         [phat pci] = mle(trgres);
                    %                         chancelevel = 0;
                    
                    case 'stepwise'
                        trgres = testresults((trialinsts == b) & strcmp(sprintf('TRG%d',t),trialtypes));
                        [phat pci] = mle(trgres,'distribution','logistic');
                        chancelevel = 0.5;
                        
                    case {'naivebayes', 'svm'}
                        trgres = testresults((trialinsts == b) & strcmp(sprintf('TRG%d',t),trialtypes));
                        [phat pci] = mle(sum(trgres),'ntrials',length(trgres),'distribution','binomial');
                        chancelevel = 0.5;
                        
                end
                
                trgest(b,t) = phat(:,1);
                trgestci(b,t,:) = pci(:,1);
            end
            
            siglevel = '';
            if trgest(b,1) > trgest(b,2)
                answer = 'YES';
                if trgestci(b,1,1) > chancelevel || trgestci(b,2,2) < chancelevel
                    siglevel = '*';
                end
            else
                answer = 'NO';
                if trgestci(b,2,1) > chancelevel || trgestci(b,1,2) < chancelevel
                    siglevel = '*';
                end
            end
            fprintf('Block %d (Inst %d): Answer is %s%s\n', b, mean(trialinsts(trialbnums == b)), answer, siglevel);
        end
        result = [];
end
