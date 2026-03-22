function audit_table = build_mb_search_domain_audit_table(meta, run_outputs)
%BUILD_MB_SEARCH_DOMAIN_AUDIT_TABLE Summarize effective MB searchable Ns domain settings.

if nargin < 1 || isempty(meta)
    meta = struct();
end
if nargin < 2
    run_outputs = repmat(struct(), 0, 1);
end

rows = cell(0, 1);
resolved_profile = string(local_getfield_or(meta, 'resolved_search_profile', local_getfield_or(meta, 'search_profile', "mb_default")));
profile_mode = string(local_getfield_or(meta, 'search_profile_mode', "debug"));
initial_range = reshape(local_getfield_or(meta, 'Ns_initial_range', [NaN NaN NaN]), 1, []);
expand_blocks = local_getfield_or(meta, 'Ns_expand_blocks', repmat(struct('name', "", 'ns_min', NaN, 'ns_step', NaN, 'ns_max', NaN), 1, 0));
hard_max = double(local_getfield_or(meta, 'Ns_hard_max', NaN));
allow_expand = logical(local_getfield_or(meta, 'Ns_allow_expand', false));
trigger_policy = string(local_safe_json(local_getfield_or(meta, 'expand_trigger_policy', struct())));
stop_policy = string(local_safe_json(local_getfield_or(meta, 'expand_stop_policy', struct())));
expand_blocks_label = string(local_blocks_label(expand_blocks));

if isempty(run_outputs)
    rows{end + 1, 1} = { ... %#ok<AGROW>
        resolved_profile, profile_mode, "", NaN, ...
        string(mat2str(initial_range)), expand_blocks_label, hard_max, allow_expand, ...
        NaN, "", "", trigger_policy, stop_policy};
else
    for idx = 1:numel(run_outputs)
        run_output = run_outputs(idx).run_output;
        for idx_run = 1:numel(local_getfield_or(run_output, 'runs', repmat(struct(), 0, 1)))
            run = run_output.runs(idx_run);
            expansion_state = local_getfield_or(run, 'expansion_state', struct());
            effective_domain = local_getfield_or(expansion_state, 'effective_search_domain', struct());
            rows{end + 1, 1} = { ... %#ok<AGROW>
                resolved_profile, profile_mode, string(local_getfield_or(run_output.sensor_group, 'name', "")), ...
                double(local_getfield_or(run, 'h_km', NaN)), ...
                string(mat2str(initial_range)), expand_blocks_label, hard_max, allow_expand, ...
                double(local_getfield_or(effective_domain, 'ns_search_max', NaN)), ...
                string(local_getfield_or(expansion_state, 'state', "")), ...
                string(local_getfield_or(expansion_state, 'stop_reason', "")), ...
                trigger_policy, stop_policy};
        end
    end
end

audit_table = cell2table(vertcat(rows{:}), 'VariableNames', { ...
    'search_profile_name', 'search_profile_mode', 'sensor_group', 'height_km', ...
    'Ns_initial_grid', 'Ns_expand_blocks', 'Ns_hard_max', 'Ns_allow_expand', ...
    'effective_ns_search_max', 'expansion_state', 'stop_reason', ...
    'expand_trigger_policy', 'expand_stop_policy'});
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end

function txt = local_blocks_label(blocks)
if isempty(blocks)
    txt = "[]";
    return;
end
parts = strings(1, numel(blocks));
for idx = 1:numel(blocks)
    block = blocks(idx);
    parts(idx) = sprintf('%s:%g:%g:%g', char(string(local_getfield_or(block, 'name', "block"))), ...
        double(local_getfield_or(block, 'ns_min', NaN)), ...
        double(local_getfield_or(block, 'ns_step', NaN)), ...
        double(local_getfield_or(block, 'ns_max', NaN)));
end
txt = strjoin(parts, '; ');
end

function txt = local_safe_json(value)
try
    txt = jsonencode(value);
catch
    txt = "<json-encode-failed>";
end
end
