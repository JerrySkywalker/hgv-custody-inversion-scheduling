function s = score_pair_interval_detY_r10(cfg, ch5case, k0, k1, pair, x_start, model)
%SCORE_PAIR_INTERVAL_DETY_R10
% Li-style interval score:
%   accumulate interval information and score by logdet(Y + eps I)

steps = k0:k1;
nSteps = numel(steps);

x_tmp = x_start;
Y = zeros(3,3);
support_steps = 0;

for ii = 1:nSteps
    k = steps(ii);
    pair_list = ch5case.candidates.pair_bank{k};

    if ~isempty(pair_list) && ismember(pair, pair_list, 'rows')
        r_tgt = x_tmp(1:3).';
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(2)))
        ];
        Jk = compute_bearing_fim_pair(r_tgt, r_sat_pair, cfg.ch5r.sensor_profile.sigma_angle_rad);
        Y = Y + Jk;
        support_steps = support_steps + 1;
    end

    if ii < nSteps
        x_tmp = model.A * x_tmp + model.b;
    end
end

Y = 0.5 * (Y + Y');
epsI = cfg.ch5r.r10.det_eps * eye(3);

% use logdet for numerical stability
[U,p] = chol(Y + epsI);
if p == 0
    logdetY = 2 * sum(log(diag(U)));
else
    logdetY = -inf;
end

s = struct();
s.pair = pair;
s.Y_interval = Y;
s.logdetY = logdetY;
s.support_steps = support_steps;
s.support_ratio = support_steps / max(nSteps,1);
end
