function trajs_in = propagate_target_family(case_items, engine_cfg)
%PROPAGATE_TARGET_FAMILY Propagate a bank of target cases.
% Inputs:
%   case_items : struct array of case definitions
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   trajs_in   : struct array with fields .case and .traj

if nargin < 2 || isempty(engine_cfg)
    engine_cfg = default_params();
end

if isempty(case_items)
    trajs_in = struct('case', {}, 'traj', {});
    return;
end

n_case = numel(case_items);
trajs_in = repmat(struct('case', case_items(1), 'traj', []), n_case, 1);

for k = 1:n_case
    trajs_in(k).case = case_items(k);
    trajs_in(k).traj = propagate_target_case(case_items(k), engine_cfg);
end
end
