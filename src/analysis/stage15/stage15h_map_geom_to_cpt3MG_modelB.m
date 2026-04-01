function MG_hat = stage15h_map_geom_to_cpt3MG_modelB(lambda_geom, baseline_km, modelB)
% 使用 H1 推荐模型 B:
% MG = beta0 + beta1*log10(lambda+eps0) + beta2*b_n + beta3*log10(lambda+eps0)*b_n

lambda_geom = max(lambda_geom, eps);
eps0 = 1e-6;

beta = modelB.beta(:);
assert(numel(beta) == 4, 'Model B beta must have length 4.');

x = log10(lambda_geom + eps0);
b_n = baseline_km / 1000;

MG_hat = beta(1) + beta(2)*x + beta(3)*b_n + beta(4)*x*b_n;
end
