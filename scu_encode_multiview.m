function Z = scu_encode_multiview(enc,F,cfg)
%SCU_ENCODE_MULTIVIEW Apply frozen fused and per-sensor encoders.
Z = struct;
Z.Fused = scu_encode(enc.Fused,F(:,enc.Masks.Fused),cfg);
Z.Mic   = scu_encode(enc.Mic,  F(:,enc.Masks.Mic),cfg);
Z.Acc   = scu_encode(enc.Acc,  F(:,enc.Masks.Acc),cfg);
Z.Gyro  = scu_encode(enc.Gyro, F(:,enc.Masks.Gyro),cfg);
end
