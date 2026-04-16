function S = derive_ch5r_state_ratios(x)
%DERIVE_CH5R_STATE_RATIOS
% Robustly derive SC/DC/LoC steps and ratios from either:
%   1) a phase runner output struct
%   2) a loaded MAT top-level struct
%
% Final reconciliation rule:
%   LoC is aligned to authoritative bubble metrics whenever available.

S = struct( ...
    'sc_steps', NaN, ...
    'dc_steps', NaN, ...
    'loc_steps', NaN, ...
    'sc_ratio', NaN, ...
    'dc_ratio', NaN, ...
    'loc_ratio', NaN, ...
    'total_steps', NaN, ...
    'source', "");

cand = x;
if isstruct(x) && isfield(x, 'outx') && isstruct(x.outx)
    cand = x.outx;
end

% ------------------------------------------
% path 1: direct summary fields
% ------------------------------------------
summary = local_find_summary_struct(cand);
if ~isempty(summary)
    S2 = local_from_summary(summary, local_guess_total_steps(cand), "direct_summary");
    S2 = local_reconcile_with_bubble(S2, cand);
    if local_is_good(S2)
        S = S2;
        return;
    end
end

% ------------------------------------------
% path 2: rebuild out_phase and run diag bundle
% ------------------------------------------
out_phase = local_build_out_phase(cand);
if ~isempty(out_phase)
    summary = local_find_summary_struct(out_phase);

    if isempty(summary)
        try
            diag_out = ch5r_build_custody_diag_bundle('suite_state_extract', out_phase);
            if isstruct(diag_out) && isfield(diag_out, 'fsm') && isstruct(diag_out.fsm) ...
                    && isfield(diag_out.fsm, 'summary') && isstruct(diag_out.fsm.summary)
                summary = diag_out.fsm.summary;
            end
        catch ME
            warning('[derive_ch5r_state_ratios] diag bundle rebuild failed: %s', ME.message);
        end
    end

    if ~isempty(summary)
        S2 = local_from_summary(summary, local_guess_total_steps(out_phase), "diag_bundle");
        S2 = local_reconcile_with_bubble(S2, out_phase);
        if local_is_good(S2)
            S = S2;
            return;
        end
    end
end

% ------------------------------------------
% path 3: state vector fallback
% ------------------------------------------
state_vals = local_find_state_vector(cand);
if ~isempty(state_vals)
    S2 = local_from_state_vector(state_vals, local_guess_total_steps(cand), "state_vector");
    S2 = local_reconcile_with_bubble(S2, cand);
    if local_is_good(S2)
        S = S2;
        return;
    end
end

% ------------------------------------------
% path 4: weak bubble fallback (LoC only)
% ------------------------------------------
total_steps = local_guess_total_steps(cand);
bubble_steps = local_first_finite(cand, { ...
    {'result','bubble_metrics','bubble_steps'}, ...
    {'bubble_metrics','bubble_steps'}, ...
    {'bubble','bubble_steps'}});

bubble_fraction = local_first_finite(cand, { ...
    {'result','bubble_metrics','bubble_fraction'}, ...
    {'bubble_metrics','bubble_fraction'}, ...
    {'bubble','bubble_fraction'}});

if isfinite(total_steps)
    S.total_steps = total_steps;
end

if isfinite(bubble_steps) && isfinite(total_steps) && total_steps > 0
    S.loc_steps = bubble_steps;
    S.loc_ratio = bubble_steps / total_steps;
    S.sc_steps = total_steps - bubble_steps;
    S.dc_steps = 0;
    S.sc_ratio = S.sc_steps / total_steps;
    S.dc_ratio = 0;
    S.source = "bubble_steps_fallback";
    return;
end

if isfinite(bubble_fraction)
    S.loc_ratio = bubble_fraction;
    S.source = "bubble_fraction_fallback";
    return;
end
end

function summary = local_find_summary_struct(cand)
summary = [];

paths = { ...
    {'diag','fsm','summary'}, ...
    {'result','fsm_summary'}, ...
    {'result','state_summary'}, ...
    {'fsm','summary'}, ...
    {'fsm_summary'}, ...
    {'state_summary'}};

for i = 1:numel(paths)
    v = local_get_field(cand, paths{i}, []);
    if isstruct(v) ...
            && (isfield(v,'sc_ratio') || isfield(v,'SC_ratio')) ...
            && (isfield(v,'dc_ratio') || isfield(v,'DC_ratio')) ...
            && (isfield(v,'loc_ratio') || isfield(v,'LoC_ratio'))
        summary = v;
        return;
    end
end
end

function x = local_find_state_vector(cand)
x = [];

paths = { ...
    {'diag','fsm','state'}, ...
    {'diag','fsm','state_series'}, ...
    {'diag','fsm','state_trace'}, ...
    {'result','state_trace','state'}, ...
    {'state_trace','state'}, ...
    {'state_trace','fsm_state'}};

for i = 1:numel(paths)
    v = local_get_field(cand, paths{i}, []);
    if ~isempty(v)
        x = v;
        return;
    end
end
end

function S = local_from_summary(summary, total_steps, source_name)
S = struct( ...
    'sc_steps', local_get_any(summary, {'sc_steps','SC_steps','sc_count','SC_count'}, NaN), ...
    'dc_steps', local_get_any(summary, {'dc_steps','DC_steps','dc_count','DC_count'}, NaN), ...
    'loc_steps', local_get_any(summary, {'loc_steps','LoC_steps','loc_count','LoC_count'}, NaN), ...
    'sc_ratio', local_get_any(summary, {'sc_ratio','SC_ratio'}, NaN), ...
    'dc_ratio', local_get_any(summary, {'dc_ratio','DC_ratio'}, NaN), ...
    'loc_ratio', local_get_any(summary, {'loc_ratio','LoC_ratio','locRatio'}, NaN), ...
    'total_steps', total_steps, ...
    'source', string(source_name));

if ~isfinite(S.total_steps)
    vals = [S.sc_steps, S.dc_steps, S.loc_steps];
    if all(isfinite(vals))
        S.total_steps = sum(vals);
    end
end

if all(isfinite([S.sc_steps, S.dc_steps, S.loc_steps])) && isfinite(S.total_steps) && S.total_steps > 0
    if ~isfinite(S.sc_ratio),  S.sc_ratio  = S.sc_steps  / S.total_steps; end
    if ~isfinite(S.dc_ratio),  S.dc_ratio  = S.dc_steps  / S.total_steps; end
    if ~isfinite(S.loc_ratio), S.loc_ratio = S.loc_steps / S.total_steps; end
end

if all(isfinite([S.sc_ratio, S.dc_ratio, S.loc_ratio])) && isfinite(S.total_steps) && S.total_steps > 0
    if ~isfinite(S.sc_steps),  S.sc_steps  = round(S.sc_ratio  * S.total_steps); end
    if ~isfinite(S.dc_steps),  S.dc_steps  = round(S.dc_ratio  * S.total_steps); end
    if ~isfinite(S.loc_steps), S.loc_steps = round(S.loc_ratio * S.total_steps); end
end
end

function S = local_from_state_vector(x, total_steps, source_name)
S = struct( ...
    'sc_steps', NaN, ...
    'dc_steps', NaN, ...
    'loc_steps', NaN, ...
    'sc_ratio', NaN, ...
    'dc_ratio', NaN, ...
    'loc_ratio', NaN, ...
    'total_steps', total_steps, ...
    'source', string(source_name));

if isempty(x)
    return;
end

if isnumeric(x)
    vals = x(:);
    vals = vals(isfinite(vals));
    if isempty(vals), return; end

    S.sc_steps = sum(vals == 0);
    S.dc_steps = sum(vals == 1);
    S.loc_steps = sum(vals == 2);

elseif iscellstr(x) || isstring(x) || iscategorical(x)
    vals = string(x(:));
    vals = upper(strtrim(vals));
    vals = vals(vals ~= "");
    if isempty(vals), return; end

    S.sc_steps = sum(vals == "SC");
    S.dc_steps = sum(vals == "DC");
    S.loc_steps = sum(vals == "LOC" | vals == "LO C" | vals == "LO_C" | vals == "LOSS" | vals == "LOSSOFCUSTODY");
else
    return;
end

if ~isfinite(S.total_steps)
    S.total_steps = S.sc_steps + S.dc_steps + S.loc_steps;
end

if isfinite(S.total_steps) && S.total_steps > 0
    S.sc_ratio  = S.sc_steps  / S.total_steps;
    S.dc_ratio  = S.dc_steps  / S.total_steps;
    S.loc_ratio = S.loc_steps / S.total_steps;
end
end

function S = local_reconcile_with_bubble(S, cand)
total_steps = S.total_steps;
if ~isfinite(total_steps)
    total_steps = local_guess_total_steps(cand);
    S.total_steps = total_steps;
end

bubble_steps = local_first_finite(cand, { ...
    {'result','bubble_metrics','bubble_steps'}, ...
    {'bubble_metrics','bubble_steps'}, ...
    {'bubble','bubble_steps'}});

bubble_fraction = local_first_finite(cand, { ...
    {'result','bubble_metrics','bubble_fraction'}, ...
    {'bubble_metrics','bubble_fraction'}, ...
    {'bubble','bubble_fraction'}});

if ~isfinite(bubble_steps) && isfinite(bubble_fraction) && isfinite(total_steps) && total_steps > 0
    bubble_steps = round(bubble_fraction * total_steps);
end

if ~(isfinite(bubble_steps) && isfinite(total_steps) && total_steps > 0)
    return;
end

loc_steps_auth = max(0, min(total_steps, round(bubble_steps)));
remain = total_steps - loc_steps_auth;

% recover old SC/DC proportion
sc_old = S.sc_steps;
dc_old = S.dc_steps;

if ~(isfinite(sc_old) && isfinite(dc_old))
    if all(isfinite([S.sc_ratio, S.dc_ratio])) && (S.sc_ratio + S.dc_ratio) > 0
        sc_old = S.sc_ratio;
        dc_old = S.dc_ratio;
    else
        sc_old = 1;
        dc_old = 0;
    end
end

den = sc_old + dc_old;
if den <= 0
    sc_new = remain;
    dc_new = 0;
else
    sc_new = round(remain * sc_old / den);
    dc_new = remain - sc_new;
end

S.sc_steps = sc_new;
S.dc_steps = dc_new;
S.loc_steps = loc_steps_auth;

S.sc_ratio = sc_new / total_steps;
S.dc_ratio = dc_new / total_steps;
S.loc_ratio = loc_steps_auth / total_steps;

S.source = string(S.source) + "+bubble_aligned";
end

function tf = local_is_good(S)
tf = isstruct(S) && all(isfinite([S.sc_ratio, S.dc_ratio, S.loc_ratio]));
end

function out_phase = local_build_out_phase(cand)
out_phase = [];

if isstruct(cand) && isfield(cand,'cfg') && isfield(cand,'case') && isfield(cand,'selection_trace') && isfield(cand,'result')
    out_phase = cand;
    if ~isfield(out_phase, 'paths')
        out_phase.paths = struct('mat_file', '');
    end
    return;
end

if ~(isstruct(cand) && isfield(cand,'cfg') && isfield(cand,'result') && isfield(cand,'selection_trace'))
    return;
end

if isfield(cand, 'case') && isstruct(cand.case)
    ch5case = cand.case;
elseif isfield(cand, 'ch5case') && isstruct(cand.ch5case)
    ch5case = cand.ch5case;
else
    return;
end

out_phase = struct();
out_phase.cfg = cand.cfg;
out_phase.case = ch5case;
out_phase.selection_trace = cand.selection_trace;
out_phase.result = cand.result;

if isfield(cand, 'bubble');      out_phase.bubble = cand.bubble; end
if isfield(cand, 'state_trace'); out_phase.state_trace = cand.state_trace; end
if isfield(cand, 'wininfo');     out_phase.wininfo = cand.wininfo; end

mat_file = '';
if isfield(cand, 'paths') && isstruct(cand.paths) && isfield(cand.paths, 'mat_file')
    mat_file = cand.paths.mat_file;
end
out_phase.paths = struct('mat_file', mat_file);
end

function total_steps = local_guess_total_steps(cand)
total_steps = local_first_finite(cand, { ...
    {'result','bubble_metrics','total_valid_steps'}, ...
    {'bubble_metrics','total_valid_steps'}, ...
    {'result','state_trace','valid_for_bubble'}, ...
    {'state_trace','valid_for_bubble'}});

if islogical(total_steps) || (isnumeric(total_steps) && ~isscalar(total_steps))
    v = total_steps;
    total_steps = sum(logical(v(:)));
end
end

function value = local_first_finite(S, path_list)
value = NaN;
for i = 1:numel(path_list)
    v = local_get_field(S, path_list{i}, NaN);
    if isscalar(v) && isnumeric(v) && isfinite(v)
        value = v;
        return;
    end
    if islogical(v) || (isnumeric(v) && ~isscalar(v))
        value = v;
        return;
    end
end
end

function value = local_get_field(S, path_cells, default_value)
value = default_value;
try
    cur = S;
    for i = 1:numel(path_cells)
        key = path_cells{i};
        if isstruct(cur) && isfield(cur, key)
            cur = cur.(key);
        else
            return;
        end
    end
    value = cur;
catch
    value = default_value;
end
end

function value = local_get_any(S, names, default_value)
value = default_value;
for i = 1:numel(names)
    if isstruct(S) && isfield(S, names{i})
        value = S.(names{i});
        return;
    end
end
end
