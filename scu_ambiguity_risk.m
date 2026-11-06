function A = scu_ambiguity_risk(C,batchCounter,cfg,seedTag)
%SCU_AMBIGUITY_RISK Label-free Rapid-Unresolved-Novelty diagnostic.
% v2.2.3 runtime gate. Uses only candidate accumulation dynamics and Mic latent
% geometry. True labels, contamination level and domain names are never used.
if nargin<4, seedTag=1; end
A=struct('CandidateN',numel(C.Ids),'Batch',batchCounter,'AccumulationRate',nan, ...
    'MicDeltaBIC',nan,'RapidNovelty',false,'LowMicStructuralConfidence',false, ...
    'HighAmbiguity',false,'UsedDim',0,'BIC1',nan,'BIC2',nan);
if batchCounter>0, A.AccumulationRate=A.CandidateN/max(1,batchCounter); end
if A.CandidateN<cfg.ambiguityMinSamples || size(C.Mic,2)<1
    return;
end
X=double(C.Mic); N=size(X,1); d=min([cfg.ambiguityLatentDims,size(X,2),N-3]);
if d<1, return; end
X=X(:,1:d); A.UsedDim=d;
med=median(X,1,'omitnan'); sc=1.4826*median(abs(X-med),1,'omitnan');
fb=std(X,0,1,'omitnan'); bad=~isfinite(sc)|sc<1e-8; sc(bad)=fb(bad); sc(~isfinite(sc)|sc<1e-8)=1;
X=(X-med)./sc; X=max(min(X,8),-8);
[A.BIC1,~]=bic1(X); [idx,~]=k2(X,seedTag,cfg.ambiguityKmeansStarts);
if isempty(idx), return; end
[A.BIC2,~]=bic2(X,idx); A.MicDeltaBIC=A.BIC1-A.BIC2;
A.RapidNovelty=isfinite(A.AccumulationRate) && A.AccumulationRate>cfg.ambiguityAccumulationRateHigh;
A.LowMicStructuralConfidence=isfinite(A.MicDeltaBIC) && A.MicDeltaBIC<cfg.ambiguityMicDeltaBICLow;
A.HighAmbiguity=A.RapidNovelty && A.LowMicStructuralConfidence;
end

function [idxBest,muBest]=k2(X,seed,nStarts)
rng(seed,'twister'); N=size(X,1); idxBest=[]; muBest=[]; best=inf;
D=pairDist(X,X); D(1:N+1:end)=-inf; [~,lin]=max(D(:)); [iFar,jFar]=ind2sub([N N],lin);
starts=cell(0,1); starts{end+1}=[X(iFar,:);X(jFar,:)]; %#ok<AGROW>
[~,ord]=sort(X(:,1),'ascend'); starts{end+1}=[X(ord(max(1,round(.25*N))),:);X(ord(min(N,round(.75*N))),:)]; %#ok<AGROW>
for r=1:max(0,nStarts-2),p=randperm(N,2);starts{end+1}=[X(p(1),:);X(p(2),:)];end %#ok<AGROW>
for s=1:numel(starts)
    mu=starts{s};idx=zeros(N,1);
    for it=1:100
        d1=sum((X-mu(1,:)).^2,2);d2=sum((X-mu(2,:)).^2,2);newIdx=1+(d2<d1);
        if all(newIdx==idx),break;end;idx=newIdx;
        if sum(idx==1)<2||sum(idx==2)<2,break;end
        mu(1,:)=mean(X(idx==1,:),1);mu(2,:)=mean(X(idx==2,:),1);
    end
    if sum(idx==1)<2||sum(idx==2)<2,continue;end
    sse=sum((X(idx==1,:)-mu(1,:)).^2,'all')+sum((X(idx==2,:)-mu(2,:)).^2,'all');
    if sse<best,best=sse;idxBest=idx;muBest=mu;end
end
end
function [bic,ll]=bic1(X)
N=size(X,1);d=size(X,2);mu=mean(X,1);vv=max(var(X,1,1),1e-4);ll=sum(logDiag(X,mu,vv));p=2*d;bic=-2*ll+p*log(N);
end
function [bic,ll]=bic2(X,idx)
N=size(X,1);d=size(X,2);L=zeros(N,2);
for k=1:2,q=idx==k;nk=sum(q);w=nk/N;mu=mean(X(q,:),1);vv=max(var(X(q,:),1,1),1e-4);L(:,k)=log(max(w,eps))+logDiag(X,mu,vv);end
mx=max(L,[],2);ll=sum(mx+log(sum(exp(L-mx),2)));p=2*(2*d)+1;bic=-2*ll+p*log(N);
end
function l=logDiag(X,mu,vv),l=-0.5*sum(log(2*pi*vv)+(X-mu).^2./vv,2);end
function D=pairDist(A,B),aa=sum(A.^2,2);bb=sum(B.^2,2)';D=sqrt(max(0,aa+bb-2*A*B'));end
