function mr_tilde = conservative_mr_from_nis(mr_hat, nis_now, cfg)
%CONSERVATIVE_MR_FROM_NIS  Conservative risk inflation using current NIS evidence.

gain = cfg.ch5.outerA_conservative_gain;
inflation = 1 + gain * max(0, nis_now);

mr_tilde = mr_hat(:) * inflation;
end
