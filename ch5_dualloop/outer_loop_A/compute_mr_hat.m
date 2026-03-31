function mr_hat = compute_mr_hat(phi_pred, nis_pred, cand_pred, cfg)
%COMPUTE_MR_HAT  Compute nominal demand-risk indicator.
%
% Larger mr_hat means higher future demand-side risk.

w_phi  = cfg.ch5.outerA_mrhat_w_phi;
w_nis  = cfg.ch5.outerA_mrhat_w_nis;
w_cand = cfg.ch5.outerA_mrhat_w_cand;

phi_risk = max(0, 1 - phi_pred(:));
nis_risk = max(0, nis_pred(:));
cand_risk = max(0, 1 - cand_pred(:));

mr_hat = w_phi * phi_risk + w_nis * nis_risk + w_cand * cand_risk;
mr_hat = max(0, mr_hat);
end
