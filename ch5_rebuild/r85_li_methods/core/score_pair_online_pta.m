function score = score_pair_online_pta(ch5case, pair_bank, pair, k_now, horizon_steps)
%SCORE_PAIR_ONLINE_PTA
% Online PTA score:
%   count how many future steps within horizon keep this pair visible in pair_bank.

n_steps = numel(pair_bank);
k2 = min(n_steps, k_now + horizon_steps - 1);
pair_sorted = sort(pair(:)).';

dur = 0;
for k = k_now:k2
    pairs_k = pair_bank{k};
    if isempty(pairs_k)
        continue;
    end
    pairs_k = sort(pairs_k, 2);
    if any(all(pairs_k == pair_sorted, 2))
        dur = dur + 1;
    end
end

score = dur;
end
