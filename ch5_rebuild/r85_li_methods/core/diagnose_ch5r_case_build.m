function info = diagnose_ch5r_case_build(case_id)
%DIAGNOSE_CH5R_CASE_BUILD
% R8X.3a:
%   Build one case and extract identifying diagnostics.

cfg = default_ch5r_params(true);
cfg = default_ch5r_r85_li_methods_params(cfg);
cfg = set_case_id_for_ch5r(cfg, case_id);

li_case = build_r85_li_case_from_current_case(cfg);
assert(isfield(li_case, 'base_case'), 'li_case.base_case missing.');
ch5case = li_case.base_case;

info = struct();
info.requested_case_id = string(case_id);

info.cfg_case_id = local_try_get(cfg, {'case_id'});
info.cfg_current_case_id = local_try_get(cfg, {'current_case_id'});
info.cfg_scenario_case_id = local_try_get(cfg, {'scenario','case_id'});
info.cfg_target_case_id = local_try_get(cfg, {'target','case_id'});
info.cfg_ch5r_case_id = local_try_get(cfg, {'ch5r','case_id'});

info.base_case_case_id = local_try_get(ch5case, {'case_id'});
info.base_case_case_name = local_try_get(ch5case, {'case_name'});
info.base_case_target_case_id = local_try_get(ch5case, {'target_case_id'});
info.base_case_scenario_case_id = local_try_get(ch5case, {'scenario','case_id'});

assert(isfield(ch5case, 'truth') && isfield(ch5case.truth, 'X'), 'truth.X missing in built case.');
X = ch5case.truth.X;
info.truth_n_steps = size(X,1);
info.truth_state_dim = size(X,2);
info.truth_first_state = X(1,:);
info.truth_last_state = X(end,:);

if isfield(ch5case.truth, 't')
    info.truth_t_start = ch5case.truth.t(1);
    info.truth_t_end = ch5case.truth.t(end);
elseif isfield(ch5case.truth, 'time_s')
    info.truth_t_start = ch5case.truth.time_s(1);
    info.truth_t_end = ch5case.truth.time_s(end);
else
    info.truth_t_start = NaN;
    info.truth_t_end = NaN;
end

assert(isfield(ch5case, 'candidates') && isfield(ch5case.candidates, 'pair_bank'), 'pair_bank missing in built case.');
info.pair_bank_n_steps = numel(ch5case.candidates.pair_bank);

% lightweight signatures for comparing cases
info.truth_first_pos = X(1,1:min(3,size(X,2)));
info.truth_last_pos = X(end,1:min(3,size(X,2)));

if size(X,2) >= 6
    info.truth_first_vel = X(1,4:6);
    info.truth_last_vel = X(end,4:6);
else
    info.truth_first_vel = [];
    info.truth_last_vel = [];
end
end

function v = local_try_get(s, path)
v = [];
try
    cur = s;
    for i = 1:numel(path)
        if isstruct(cur) && isfield(cur, path{i})
            cur = cur.(path{i});
        else
            v = [];
            return;
        end
    end
    v = cur;
catch
    v = [];
end
end
