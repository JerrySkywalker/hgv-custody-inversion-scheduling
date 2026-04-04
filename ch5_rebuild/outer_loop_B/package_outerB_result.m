function out = package_outerB_result(k_idx, pair_sel, weights, sel_eval)
%PACKAGE_OUTERB_RESULT Package outerB result for logging/downstream use.

out = struct();
out.k = k_idx;
out.pair = pair_sel;
out.score = sel_eval.score;
out.M_G_pair = sel_eval.M_G;
out.lambda_max_PR_plus = sel_eval.lambda_max_PR_plus;
out.switch_cost = sel_eval.switch_cost;
out.resource_cost = sel_eval.resource_cost;
out.alpha_k = weights.alpha_k;
out.beta_k = weights.beta_k;
out.eta_k = weights.eta_k;
out.mu_k = weights.mu_k;
end
