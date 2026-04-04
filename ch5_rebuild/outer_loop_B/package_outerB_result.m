function out = package_outerB_result(k_idx, pair_sel, weights, sel_eval)
%PACKAGE_OUTERB_RESULT Package outerB result for logging/downstream use.
%
% Compatible with R8.5b normalized scoring output fields.

out = struct();
out.k = k_idx;
out.pair = pair_sel;
out.score = sel_eval.score;

out.M_G_pair = sel_eval.raw_MG;
out.lambda_max_PR_plus = sel_eval.raw_lambda_max_PR_plus;
out.switch_cost = sel_eval.raw_switch_cost;
out.resource_cost = sel_eval.raw_resource_cost;

out.norm_MG = sel_eval.norm_MG;
out.norm_PR = sel_eval.norm_PR;
out.norm_SC = sel_eval.norm_SC;
out.norm_RC = sel_eval.norm_RC;

out.tie_metric = sel_eval.tie_metric;

out.alpha_k = weights.alpha_k;
out.beta_k = weights.beta_k;
out.eta_k = weights.eta_k;
out.mu_k = weights.mu_k;
end
