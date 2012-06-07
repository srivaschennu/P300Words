function result = lda(clsfyrtype,clsfyrmode,EEG,varargin)

dsfactor = 5;
trainchan = {'E11' 'E24'  'E62'   'E65'   'E75'   'E90'  'E124' 'Cz'};
for t = 1:length(trainchan)
    trainchan{t} = find(strcmp(trainchan{t},{EEG.chanlocs.labels}));
end
trainchan = cell2mat(trainchan);

% trainchan = 62;
trainwin = [0 800];
trainwin = find(EEG.times <= trainwin(1),1,'last'):find(EEG.times >= trainwin(2),1,'first');

fprintf('Extracting features from %s.\n',EEG.setname);
data = reshape(permute(EEG.data(trainchan,trainwin,:), [3 2 1]), EEG.trials, length(trainchan)*length(trainwin));
features = zeros(EEG.trials,length(trainchan)*length(trainwin));
labels = zeros(EEG.trials,1);
trialtypes = cell(EEG.trials,1);
trialbnums = zeros(EEG.trials,1);
trialinsts = zeros(EEG.trials,1);

typelist = {'TRG1','TRG2','DIST'};
%typelist = {'TRG1','TRG2'};

trialcount = 0;
for t = 1:EEG.trials
    trialtype = EEG.epoch(1,t).eventtype{1,(cell2mat(EEG.epoch(1,t).eventlatency) == 0)};
    
    if sum(strcmp(trialtype,typelist)) > 0
        trialcount = trialcount + 1;
        features(trialcount,:) = data(t,:);
        trialtypes{trialcount} = trialtype;
        trialbnums(trialcount) = EEG.epoch(1,t).eventBNUM{1,(cell2mat(EEG.epoch(1,t).eventlatency) == 0)};
        if isfield(EEG.epoch,'eventINUM')
            trialinsts(trialcount) = EEG.epoch(1,t).eventINUM{1,(cell2mat(EEG.epoch(1,t).eventlatency) == 0)};
        end
        
        if strcmp('TRG1',trialtype)
            labels(trialcount) = 1;
        elseif strcmp('TRG2',trialtype) || strcmp('DIST',trialtype)
            labels(trialcount) = 0;
        end
    end
end

features = features(1:trialcount,:);
labels = labels(1:trialcount,1);
trialtypes = trialtypes(1:trialcount,1);
trialbnums = trialbnums(1:trialcount,1);
trialinsts = trialinsts(1:trialcount,1);

features = double(downsample(features',dsfactor)');

fmean = mean(features,1);
fstd = std(features,0,1);

switch clsfyrmode
    
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
