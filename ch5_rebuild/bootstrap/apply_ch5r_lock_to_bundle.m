function bundle = apply_ch5r_lock_to_bundle(bundle, cfg)
%APPLY_CH5R_LOCK_TO_BUNDLE
% If runtime override requests constellation lock, overwrite bootstrap
% theta_star/theta_plus/gamma_req using the selected lock file.
%
% This keeps existing Phase runner signatures unchanged.

rt = load_ch5r_runtime_override();
if isempty(rt) || ~isstruct(rt) || ~isfield(rt, 'enabled') || ~logical(rt.enabled)
    return;
end

if ~isfield(rt, 'use_constellation_lock') || ~logical(rt.use_constellation_lock)
    return;
end

if ~isfield(rt, 'lock_name') || isempty(rt.lock_name)
    lock_name = 'ch5_constellation_lock';
else
    lock_name = char(string(rt.lock_name));
end

lock_out = read_ch5r_constellation_lock(struct('lock_name', lock_name));
L = lock_out.lock;

current_case_id = '';
if isfield(bundle, 'target_case') && isstruct(bundle.target_case) && isfield(bundle.target_case, 'case_id')
    current_case_id = bundle.target_case.case_id;
end
if isempty(current_case_id) && isfield(rt, 'case_id')
    current_case_id = rt.case_id;
end

bundle.gamma_req = L.gamma_req;

bundle.theta_star = L.theta_star;
bundle.theta_plus = L.theta_plus;

% Preserve locked constellation, but retag the active runtime case so
% downstream logs/tests do not keep stale N01 labels.
bundle.theta_star.case_id = current_case_id;
bundle.theta_plus.case_id = current_case_id;

bundle.theta_star.selected_from_lock_case_id = L.target_case.case_id;
bundle.theta_plus.selected_from_lock_case_id = L.target_case.case_id;

if ~isfield(bundle, 'target_case') || ~isstruct(bundle.target_case)
    bundle.target_case = struct();
end
bundle.target_case.case_id = current_case_id;
bundle.target_case.family = local_guess_family(current_case_id);
bundle.target_case.source = 'runtime_override+constellation_lock';

% Keep source stage cache paths from lock
if isfield(L, 'target_case') && isstruct(L.target_case)
    if isfield(L.target_case, 'stage04_cache_file')
        bundle.target_case.stage04_cache_file = L.target_case.stage04_cache_file;
    end
    if isfield(L.target_case, 'stage05_cache_file')
        bundle.target_case.stage05_cache_file = L.target_case.stage05_cache_file;
    end
end

bundle.used_constellation_lock = true;
bundle.constellation_lock_name = lock_name;
bundle.constellation_lock = L;

% keep cfg visible for diagnostics if useful
if nargin >= 2
    bundle.runtime_cfg_present = ~isempty(cfg);
end
end

function family = local_guess_family(case_id)
if startsWith(case_id, 'N', 'IgnoreCase', true)
    family = 'nominal';
elseif startsWith(case_id, 'H', 'IgnoreCase', true)
    family = 'heading';
elseif startsWith(case_id, 'C', 'IgnoreCase', true)
    family = 'critical';
else
    family = 'unknown';
end
end
