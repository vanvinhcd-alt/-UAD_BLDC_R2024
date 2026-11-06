function Z = scu_encode(enc,F,cfg)
%SCU_ENCODE Apply frozen source-normal representation.
X=(double(F)-enc.Median)./enc.Scale;
X=max(min(X,cfg.robustZClip),-cfg.robustZClip);
Z=(X-enc.RobustMean)*enc.Projection;
Z(~isfinite(Z))=0;
end
