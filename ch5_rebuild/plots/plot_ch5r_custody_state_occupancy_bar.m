function out = plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, output_dir, visible_mode, occupancy_mode, body_range_s)
%PLOT_CH5R_CUSTODY_STATE_OCCUPANCY_BAR
% Plot stacked bar chart for SC/DC/LoC occupancy ratios.
%
% Usage:
%   plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, outdir)
%   plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, outdir, 'off', 'full')
%   plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, outdir, 'off', 'body_only')
%   plot_ch5r_custody_state_occupancy_bar(out5d, out9d, out10d, outdir, 'off', 'body_only', [29 770])

if nargin < 5 || isempty(visible_mode)
    visible_mode = 'off';
end
if nargin < 6 || isempty(occupancy_mode)
    occupancy_mode = 'full';
end
if nargin < 7
    body_range_s = [];
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

disp('[plot][occupancy] start')

method_labels = {'Predictive baseline', 'Bubble-oriented', 'Interval backend'};

s5  = local_extract_summary(out5d,  occupancy_mode, body_range_s);
s9  = local_extract_summary(out9d,  occupancy_mode, body_range_s);
s10 = local_extract_summary(out10d, occupancy_mode, body_range_s);

phase_ids = {'R5','R9','R10'};
sc_ratio  = [s5.sc_ratio;  s9.sc_ratio;  s10.sc_ratio];
dc_ratio  = [s5.dc_ratio;  s9.dc_ratio;  s10.dc_ratio];
loc_ratio = [s5.loc_ratio; s9.loc_ratio; s10.loc_ratio];

T = table( ...
    string(phase_ids(:)), ...
    string(method_labels(:)), ...
    sc_ratio, dc_ratio, loc_ratio, ...
    'VariableNames', {'phase_id','method_label','SC_ratio','DC_ratio','LoC_ratio'});

fig = figure('Visible', visible_mode, 'Color', 'w', 'Position', [120 120 980 620]);

Y = [sc_ratio, dc_ratio, loc_ratio];
bh = bar(Y, 'stacked', 'LineWidth', 0.8);
grid on;
ylim([0 1]);
xticks(1:3);
xticklabels(method_labels);
xtickangle(12);
ylabel('occupancy ratio', 'Interpreter', 'latex');

if strcmpi(occupancy_mode, 'body_only')
    title('SC / DC / LoC occupancy comparison (body-only)', 'Interpreter', 'latex');
    file_tag = 'body_only';
else
    title('SC / DC / LoC occupancy comparison', 'Interpreter', 'latex');
    file_tag = 'full';
end

legend({'SC','DC','LoC'}, 'Interpreter', 'latex', 'Location', 'eastoutside');

for i = 1:size(Y,1)
    y_sc = Y(i,1);
    y_dc = Y(i,2);
    y_loc = Y(i,3);

    if y_sc > 0.03
        text(i, y_sc/2, sprintf('%.1f%%', 100*y_sc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    if y_dc > 0.03
        text(i, y_sc + y_dc/2, sprintf('%.1f%%', 100*y_dc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
    if y_loc > 0.03
        text(i, y_sc + y_dc + y_loc/2, sprintf('%.1f%%', 100*y_loc), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');
    end
end

fig_file = fullfile(output_dir, ['ch5r_custody_state_occupancy_bar_' file_tag '.png']);
tbl_file = fullfile(output_dir, ['ch5r_custody_state_occupancy_bar_' file_tag '.csv']);

writetable(T, tbl_file);
saveas(fig, fig_file);
close(fig);

disp('[plot][occupancy] done')
disp(T)

out = struct();
out.fig_file = fig_file;
out.table_file = tbl_file;
out.table = T;
out.method_labels = method_labels;
out.occupancy_mode = occupancy_mode;
out.summary = struct('R5', s5, 'R9', s9, 'R10', s10);
end

function s = local_extract_summary(outx, occupancy_mode, body_range_s)
if strcmpi(occupancy_mode, 'full')
    s = local_get_full_summary(outx);
    s.mode = 'full';
    return;
end

[state_vals, time_vals] = local_get_state_series(outx);
if isempty(state_vals) || isempty(time_vals)
    warning('plot_ch5r_custody_state_occupancy_bar:noSeries', ...
        'Body-only mode failed to find state/time series. Fallback to full summary.');
    s = local_get_full_summary(outx);
    s.mode = 'full_fallback';
    return;
end

if isempty(body_range_s)
    body_range_s = local_guess_body_range(outx, time_vals);
end

mask = (time_vals >= body_range_s(1)) & (time_vals <= body_range_s(2));
if ~any(mask)
    warning('plot_ch5r_custody_state_occupancy_bar:emptyMask', ...
        'Body-only mask is empty. Fallback to full summary.');
    s = local_get_full_summary(outx);
    s.mode = 'full_fallback';
    return;
end

state_sel = state_vals(mask);
[sc_ratio, dc_ratio, loc_ratio] = local_compute_ratios_from_state(state_sel);

s = struct();
s.sc_ratio = sc_ratio;
s.dc_ratio = dc_ratio;
s.loc_ratio = loc_ratio;
s.mode = 'body_only';
s.body_range_s = body_range_s(:).';
s.n_samples = numel(state_sel);
end

function s = local_get_full_summary(outx)
summary = [];
if isfield(outx, 'diag') && isstruct(outx.diag) && isfield(outx.diag, 'fsm') && isstruct(outx.diag.fsm) ...
        && isfield(outx.diag.fsm, 'summary') && isstruct(outx.diag.fsm.summary)
    summary = outx.diag.fsm.summary;
end

if ~isempty(summary) ...
        && isfield(summary, 'sc_ratio') ...
        && isfield(summary, 'dc_ratio') ...
        && isfield(summary, 'loc_ratio')
    s = struct();
    s.sc_ratio = double(summary.sc_ratio);
    s.dc_ratio = double(summary.dc_ratio);
    s.loc_ratio = double(summary.loc_ratio);
    s.mode = 'full';
    return;
end

[state_vals, ~] = local_get_state_series(outx);
if isempty(state_vals)
    error('plot_ch5r_custody_state_occupancy_bar:noSummary', ...
        'Cannot find occupancy summary or state series.');
end

[sc_ratio, dc_ratio, loc_ratio] = local_compute_ratios_from_state(state_vals);

s = struct();
s.sc_ratio = sc_ratio;
s.dc_ratio = dc_ratio;
s.loc_ratio = loc_ratio;
s.mode = 'full_rebuilt';
s.n_samples = numel(state_vals);
end

function [state_vals, time_vals] = local_get_state_series(outx)
state_vals = [];
time_vals = [];

cand_states = { ...
    {'diag','fsm','state_series'}, ...
    {'diag','fsm','state_trace'}, ...
    {'diag','fsm','state_idx'}, ...
    {'diag','fsm','state'}, ...
    {'diag','custody_state'}, ...
    {'fsm','state_series'}, ...
    {'fsm','state_trace'}, ...
    {'fsm','state_idx'}, ...
    {'fsm','state'}};

cand_times = { ...
    {'diag','fsm','time_s'}, ...
    {'diag','time_s'}, ...
    {'time_s'}, ...
    {'truth','time_s'}};

for i = 1:numel(cand_states)
    v = local_get_nested(outx, cand_states{i});
    if ~isempty(v)
        state_vals = v;
        break;
    end
end

for i = 1:numel(cand_times)
    v = local_get_nested(outx, cand_times{i});
    if ~isempty(v)
        time_vals = v;
        break;
    end
end

if isempty(state_vals)
    return;
end

state_vals = state_vals(:);

if isempty(time_vals)
    time_vals = (0:numel(state_vals)-1).';
else
    time_vals = time_vals(:);
end

n = min(numel(state_vals), numel(time_vals));
state_vals = state_vals(1:n);
time_vals = time_vals(1:n);
end

function body_range_s = local_guess_body_range(outx, time_vals)
body_range_s = [];

cand_ranges = { ...
    {'diag','body_range_s'}, ...
    {'diag','fsm','body_range_s'}, ...
    {'body_range_s'}};

for i = 1:numel(cand_ranges)
    v = local_get_nested(outx, cand_ranges{i});
    if isnumeric(v) && numel(v) == 2
        body_range_s = double(v(:)).';
        return;
    end
end

cand_masks = { ...
    {'diag','valid_body_mask'}, ...
    {'diag','fsm','valid_body_mask'}, ...
    {'valid_body_mask'}};

for i = 1:numel(cand_masks)
    v = local_get_nested(outx, cand_masks{i});
    if islogical(v) || isnumeric(v)
        v = logical(v(:));
        n = min(numel(v), numel(time_vals));
        v = v(1:n);
        t = time_vals(1:n);
        idx = find(v);
        if ~isempty(idx)
            body_range_s = [t(idx(1)), t(idx(end))];
            return;
        end
    end
end

Tw_s = local_guess_window_length(outx);
if isempty(Tw_s)
    body_range_s = [time_vals(1), time_vals(end)];
    return;
end

left_trim = floor((Tw_s - 1) / 2);
right_trim = ceil((Tw_s - 1) / 2);
body_range_s = [time_vals(1) + left_trim, time_vals(end) - right_trim];
end

function Tw_s = local_guess_window_length(outx)
Tw_s = [];

cand_Tw = { ...
    {'cfg','stage04','Tw_s'}, ...
    {'cfg','ch5r','window','Tw_s'}, ...
    {'cfg','ch5r','metrics','Tw_s'}, ...
    {'diag','window','Tw_s'}, ...
    {'diag','Tw_s'}, ...
    {'Tw_s'}};

for i = 1:numel(cand_Tw)
    v = local_get_nested(outx, cand_Tw{i});
    if isnumeric(v) && isscalar(v) && isfinite(v) && v > 1
        Tw_s = double(v);
        return;
    end
end
end

function [sc_ratio, dc_ratio, loc_ratio] = local_compute_ratios_from_state(state_vals)
state_vals = state_vals(:);
n = numel(state_vals);

if n == 0
    sc_ratio = NaN;
    dc_ratio = NaN;
    loc_ratio = NaN;
    return;
end

if iscellstr(state_vals) || isstring(state_vals) || ischar(state_vals)
    state_str = string(state_vals);
    state_str = upper(strtrim(state_str));

    is_sc  = state_str == "SC";
    is_dc  = state_str == "DC";
    is_loc = (state_str == "LOC") | (state_str == "LO C") | (state_str == "LO_C") | (state_str == "LOSS") | (state_str == "LOSSOFCUSTODY");
else
    vals = double(state_vals);
    u = unique(vals(~isnan(vals)));
    u = sort(u(:));

    if numel(u) == 1
        is_sc  = vals == u(1);
        is_dc  = false(size(vals));
        is_loc = false(size(vals));
    elseif numel(u) == 2
        is_sc  = vals == u(1);
        is_dc  = vals == u(2);
        is_loc = false(size(vals));
    else
        is_sc  = vals == u(1);
        is_dc  = vals == u(2);
        is_loc = vals == u(end);
    end
end

sc_ratio = sum(is_sc)  / n;
dc_ratio = sum(is_dc)  / n;
loc_ratio = sum(is_loc) / n;
end

function v = local_get_nested(s, path_cells)
v = [];
cur = s;
for k = 1:numel(path_cells)
    key = path_cells{k};
    if isstruct(cur) && isfield(cur, key)
        cur = cur.(key);
    else
        return;
    end
end
v = cur;
end
