function P = scu_build_protocol(data,cfg,seed,contaminationLevel)
%SCU_BUILD_PROTOCOL Group-disjoint continual benchmark for SAFE-CL-UAD v2.
% Labels are visible only to this benchmark builder and the evaluator.
% The learner never receives TrueLabel, contamination level, or transitions.

rng(seed,'twister');
M=data.meta; n=height(M); allIdx=(1:n)';
if ~ismember('GroupID',M.Properties.VariableNames)
    error('SAFECL:GroupID','Metadata has no GroupID. Rebuild metadata/cache with v2.2.3.');
end

%% 1) Source-normal initialization split by GROUP, never by segment.
src=find(M.Split=="train" & M.DatasetDomain=="source" & M.TrueLabel==0);
if numel(src)<max(30,cfg.minBankFit+cfg.minBankCal+5)
    error('SAFECL:Protocol','Too few source-normal train segments: %d',numel(src));
end
[srcFitG,srcCalG,srcAnchorG]=splitSourceGroups(src,M,cfg);
fitIdx=src(ismember(M.GroupID(src),srcFitG));
calIdx=src(ismember(M.GroupID(src),srcCalG));
anchorIdx=src(ismember(M.GroupID(src),srcAnchorG));
if numel(fitIdx)<cfg.minBankFit || numel(calIdx)<cfg.minBankCal || numel(anchorIdx)<5
    error('SAFECL:Protocol','Group split too small: fit=%d cal=%d anchor=%d.',numel(fitIdx),numel(calIdx),numel(anchorIdx));
end

%% 2) Official test split by GroupID into fixed evaluation and stream pools.
testIdx=find(M.Split=="test");
[evalGroups,streamGroups]=splitTestGroups(testIdx,M,cfg);
evalIdx=testIdx(ismember(M.GroupID(testIdx),evalGroups));
streamTestPool=testIdx(ismember(M.GroupID(testIdx),streamGroups));

%% 3) Target-train normal stream; all its groups remain stream-only.
tgtTrain=zeros(0,1); targetTrainKeys=strings(0,1);
if cfg.includeTargetTrainInStream
    tgtTrain=find(M.Split=="train" & M.DatasetDomain=="target" & M.TrueLabel==0);
    targetTrainKeys=unique(M.EpisodeKey(tgtTrain),'stable');
end

%% 4) Controlled contamination budget over the already group-disjoint stream.
testNormalPool=streamTestPool(M.TrueLabel(streamTestPool)==0);
testAnomalyPool=streamTestPool(M.TrueLabel(streamTestPool)==1);
baseNormalN=numel(tgtTrain)+numel(testNormalPool);
if contaminationLevel < 0 || contaminationLevel >= 1
    requestedAnomalyN=numel(testAnomalyPool);
    selectedAglobal=testAnomalyPool(:);
else
    requestedAnomalyN=round(contaminationLevel/max(1e-9,1-contaminationLevel)*baseNormalN);
    requestedAnomalyN=min(max(requestedAnomalyN,0),numel(testAnomalyPool));
    selectedAglobal=stratifiedSelect(testAnomalyPool,M.EpisodeKey(testAnomalyPool),requestedAnomalyN);
end
selectedAglobal=sort(unique(selectedAglobal(:)));

% Part of selected target anomalies may appear in early unlabeled adaptation.
adaptInjectedA=zeros(0,1);
if cfg.includeTargetTrainInStream && ~isempty(selectedAglobal) && cfg.contaminationAdaptFraction>0
    eligible=selectedAglobal(M.DatasetDomain(selectedAglobal)=="target" & ismember(M.EpisodeKey(selectedAglobal),targetTrainKeys));
    nAdapt=round(cfg.contaminationAdaptFraction*numel(eligible));
    adaptInjectedA=stratifiedSelect(eligible,M.EpisodeKey(eligible),nAdapt);
end
adaptInjectedA=sort(unique(adaptInjectedA(:)));
testInjectedA=setdiff(selectedAglobal,adaptInjectedA,'stable');

%% 5) Sequential episodes.
episodes=struct('Name',{},'StreamIdx',{},'TaskKey',{},'Stage',{},'ActualContamination',{});
if cfg.includeTargetTrainInStream
    for k=1:numel(targetTrainKeys)
        key=targetTrainKeys(k);
        normalIdx=tgtTrain(M.EpisodeKey(tgtTrain)==key);
        anomalyIdx=adaptInjectedA(M.EpisodeKey(adaptInjectedA)==key);
        idx=[normalIdx(:);anomalyIdx(:)];
        if cfg.shuffleWithinEpisode && ~isempty(idx), idx=idx(randperm(numel(idx))); end
        episodes(end+1)=makeEpisode("ADAPT|"+key,idx,key,"ADAPT",M); %#ok<AGROW>
    end
end
keys=unique(M.EpisodeKey(testIdx),'stable');
for k=1:numel(keys)
    pool=streamTestPool(M.EpisodeKey(streamTestPool)==keys(k));
    normal=pool(M.TrueLabel(pool)==0);
    anomaly=pool(M.TrueLabel(pool)==1);
    selectedA=anomaly(ismember(anomaly,testInjectedA));
    idx=[normal(:);selectedA(:)];
    if cfg.shuffleWithinEpisode && ~isempty(idx), idx=idx(randperm(numel(idx))); end
    if isempty(idx), continue; end
    episodes(end+1)=makeEpisode("TEST|"+keys(k),idx,keys(k),"TEST",M); %#ok<AGROW>
end
if isempty(episodes), error('SAFECL:Protocol','No stream episodes were constructed.'); end

%% 6) Hard integrity audit at BOTH sample and GroupID level.
streamIdx=unique(vertcat(episodes.StreamIdx));
sets={fitIdx,calIdx,anchorIdx,streamIdx,evalIdx};
setNames=["SourceFit","SourceCal","SourceAnchor","Stream","Evaluation"];
for a=1:numel(sets)
    for b=a+1:numel(sets)
        ov=intersect(sets{a},sets{b});
        if ~isempty(ov)
            error('SAFECL:Leakage','Sample overlap %s vs %s: %d.',setNames(a),setNames(b),numel(ov));
        end
        gov=intersect(unique(M.GroupID(sets{a})),unique(M.GroupID(sets{b})));
        if cfg.requireGroupDisjoint && ~isempty(gov)
            error('SAFECL:GroupLeakage','GroupID overlap %s vs %s: %d groups. Example: %s', ...
                setNames(a),setNames(b),numel(gov),gov(1));
        end
    end
end

used=unique([fitIdx;calIdx;anchorIdx;streamIdx;evalIdx]); unused=setdiff(allIdx,used);
actualStreamCont=sum(M.TrueLabel(streamIdx)==1)/max(1,numel(streamIdx));
if contaminationLevel>=0 && contaminationLevel<1
    contaminationError=abs(actualStreamCont-contaminationLevel);
    withinTolerance=contaminationError<=cfg.contaminationAbsTolerance;
else
    contaminationError=nan; withinTolerance=true;
end

evalKeys=unique(M.EpisodeKey(evalIdx),'stable');
P=struct;
P.seed=seed; P.contaminationLevel=contaminationLevel;
P.sourceFitIdx=fitIdx; P.sourceCalIdx=calIdx; P.sourceAnchorIdx=anchorIdx;
P.evalIdx=sort(unique(evalIdx)); P.evalTaskKeys=evalKeys; P.episodes=episodes;
P.streamIdx=streamIdx; P.unusedIdx=unused; P.selectedAnomalyIdx=selectedAglobal;
P.streamManifest=makeStreamManifest(episodes,M);

P.protocolAudit=table(seed,contaminationLevel,actualStreamCont,contaminationError,withinTolerance, ...
    baseNormalN,requestedAnomalyN,numel(selectedAglobal),numel(adaptInjectedA),numel(testInjectedA), ...
    numel(fitIdx),numel(calIdx),numel(anchorIdx),numel(streamIdx),numel(evalIdx),numel(unused), ...
    numel(unique(M.GroupID(fitIdx))),numel(unique(M.GroupID(calIdx))),numel(unique(M.GroupID(anchorIdx))), ...
    numel(unique(M.GroupID(streamIdx))),numel(unique(M.GroupID(evalIdx))),numel(episodes),numel(evalKeys), ...
    'VariableNames',{'Seed','NominalContamination','ActualStreamContamination','ContaminationAbsError', ...
    'ContaminationWithinTolerance','BaseNormalStreamN','RequestedAnomalyN','SelectedAnomalyN','AdaptInjectedAnomalyN', ...
    'TestInjectedAnomalyN','SourceFitN','SourceCalN','SourceAnchorN','StreamN','EvaluationN','UnusedN', ...
    'SourceFitGroups','SourceCalGroups','SourceAnchorGroups','StreamGroups','EvaluationGroups','Episodes','EvaluationTasks'});
P.episodeAudit=makeEpisodeAudit(episodes,M,seed,contaminationLevel);
P.groupAudit=makeGroupAudit(sets,setNames,M,seed,contaminationLevel);
end

function E=makeEpisode(name,idx,key,stage,M)
actual=sum(M.TrueLabel(idx)==1)/max(1,numel(idx));
E=struct('Name',name,'StreamIdx',idx(:),'TaskKey',key,'Stage',stage,'ActualContamination',actual);
end

function [fitG,calG,anchorG]=splitSourceGroups(src,M,cfg)
g=unique(M.GroupID(src),'stable');
if numel(g)<3, error('SAFECL:GroupID','Need at least 3 source-normal groups; found %d.',numel(g)); end
g=g(randperm(numel(g)));
counts=arrayfun(@(k)sum(M.GroupID(src)==g(k)),1:numel(g));
total=sum(counts); targetFit=cfg.sourceFitFraction*total; targetCal=cfg.sourceCalFraction*total;
fitG=strings(0,1); calG=strings(0,1); anchorG=strings(0,1); nf=0; nc=0;
for k=1:numel(g)
    if nf<targetFit && numel(g)-k+1>2
        fitG(end+1,1)=g(k); nf=nf+counts(k); %#ok<AGROW>
    elseif nc<targetCal && numel(g)-k+1>1
        calG(end+1,1)=g(k); nc=nc+counts(k); %#ok<AGROW>
    else
        anchorG(end+1,1)=g(k); %#ok<AGROW>
    end
end
if isempty(calG), calG=anchorG(1); anchorG(1)=[]; end
if isempty(anchorG), anchorG=calG(end); calG(end)=[]; end
end

function [evalG,streamG]=splitTestGroups(testIdx,M,cfg)
% Group-level stratification. A group can never be split between eval/stream.
g=unique(M.GroupID(testIdx),'stable');
stratum=strings(numel(g),1);
for k=1:numel(g)
    ii=testIdx(M.GroupID(testIdx)==g(k));
    ek=unique(M.EpisodeKey(ii),'stable'); y=unique(M.TrueLabel(ii));
    if numel(ek)==1 && numel(y)==1
        stratum(k)=ek(1)+"|y="+string(y);
    elseif numel(ek)==1
        stratum(k)=ek(1)+"|y=mixed";
    else
        stratum(k)="mixedEpisode|"+g(k);
    end
end
evalG=strings(0,1); streamG=strings(0,1);
us=unique(stratum,'stable');
for s=1:numel(us)
    q=g(stratum==us(s)); q=q(randperm(numel(q)));
    if numel(q)==1
        % Prefer evaluation for singleton strata; other strata still supply stream.
        evalG(end+1,1)=q(1); %#ok<AGROW>
    else
        nEval=max(1,round(cfg.evalFraction*numel(q))); nEval=min(nEval,numel(q)-1);
        evalG=[evalG;q(1:nEval)]; streamG=[streamG;q(nEval+1:end)]; %#ok<AGROW>
    end
end
% If group structure is extremely coarse, move whole groups (never rows) to ensure a stream exists.
if isempty(streamG) && numel(evalG)>1
    streamG=evalG(end); evalG(end)=[];
end
end

function selected=stratifiedSelect(idx,key,nSelect)
selected=zeros(0,1); if nSelect<=0 || isempty(idx), return; end
nSelect=min(nSelect,numel(idx)); uk=unique(key,'stable'); groups=cell(numel(uk),1);
for k=1:numel(uk), q=idx(key==uk(k)); groups{k}=q(randperm(numel(q))); end
r=1;
while numel(selected)<nSelect
    order=randperm(numel(uk)); added=false;
    for kk=order
        if r<=numel(groups{kk})
            selected(end+1,1)=groups{kk}(r); added=true; %#ok<AGROW>
            if numel(selected)>=nSelect, break; end
        end
    end
    if ~added, break; end
    r=r+1;
end
end

function T=makeStreamManifest(episodes,M)
rows=cell(numel(episodes),1);
for e=1:numel(episodes)
    ii=episodes(e).StreamIdx;
    rows{e}=table(repmat(e,numel(ii),1),repmat(episodes(e).Name,numel(ii),1),M.SampleID(ii),M.GroupID(ii), ...
        M.TrueLabel(ii),M.DatasetDomain(ii),M.EpisodeKey(ii), ...
        'VariableNames',{'EpisodeNumber','EpisodeName','SampleID','GroupID','TrueLabel_EVAL_ONLY','Domain','TaskKey'});
end
T=vertcat(rows{:});
end

function T=makeEpisodeAudit(episodes,M,seed,lev)
rows=cell(numel(episodes),1);
for e=1:numel(episodes)
    ii=episodes(e).StreamIdx;
    rows{e}=table(seed,lev,e,episodes(e).Name,episodes(e).Stage,episodes(e).TaskKey,numel(ii), ...
        numel(unique(M.GroupID(ii))),sum(M.TrueLabel(ii)==1),episodes(e).ActualContamination, ...
        'VariableNames',{'Seed','NominalContamination','EpisodeNumber','EpisodeName','Stage','TaskKey', ...
        'StreamN','Groups','AnomalyN_EVAL_ONLY','ActualContamination_EVAL_ONLY'});
end
T=vertcat(rows{:});
end

function T=makeGroupAudit(sets,names,M,seed,lev)
rows={}; r=0;
for a=1:numel(sets)
    g=unique(M.GroupID(sets{a}));
    r=r+1; rows{r}=table(seed,lev,names(a),numel(sets{a}),numel(g), ...
        'VariableNames',{'Seed','NominalContamination','Role','Segments','Groups'}); %#ok<AGROW>
end
T=vertcat(rows{:});
end
