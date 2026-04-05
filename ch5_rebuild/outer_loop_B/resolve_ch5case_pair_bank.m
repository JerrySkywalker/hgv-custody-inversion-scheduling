function pair_bank_k = resolve_ch5case_pair_bank(ch5case, k)
%RESOLVE_CH5CASE_PAIR_BANK Resolve time-varying pair bank from ch5case.
%
% Expected preferred path:
%   ch5case.candidates.pair_bank{k}
%
% Fallbacks are included to reduce brittleness.

assert(isstruct(ch5case), 'ch5case must be a struct.');
assert(isnumeric(k) && isscalar(k) && k >= 1, 'k invalid.');

if isfield(ch5case, 'candidates')
    cands = ch5case.candidates;

    if isfield(cands, 'pair_bank') && iscell(cands.pair_bank)
        pair_bank_k = cands.pair_bank{k};
        return;
    end

    if isfield(cands, 'pair_bank_by_step') && iscell(cands.pair_bank_by_step)
        pair_bank_k = cands.pair_bank_by_step{k};
        return;
    end

    if isfield(cands, 'pair_candidates') && iscell(cands.pair_candidates)
        pair_bank_k = cands.pair_candidates{k};
        return;
    end
end

error(['Unable to resolve time-varying pair bank from ch5case. ', ...
       'Please inspect fields under ch5case.candidates.']);
end
