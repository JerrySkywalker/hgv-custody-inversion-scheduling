function out = plot_ch5r_rmse_proxy_comparison(out4, out5, out_dir, stamp)
% Plot R4-real vs R5-real RMSE comparison using body-only full-window region.
% Priority:
%   1) replay / diag replay true RMSE
%   2) diag.rmse
%   3) rmse_metrics.rmse_proxy_timeline
%   4) legacy lambda_min -> 1/sqrt(lambda) proxy

if nargin < 4 || isempty(stamp)
    stamp = datestr(now, 'yyyymmdd_HHMMSS');
end
if nargin < 3 || isempty(out_dir)
    out_dir = pwd;
end
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

[t4, y4, src4] = local_extract_time_and_rmse(out4, 'R4');
[t5, y5, src5] = local_extract_time_and_rmse(out5, 'R5');

n = min([numel(t4), numel(y4), numel(t5), numel(y5)]);
t4 = t4(1:n);
y4 = y4(1:n);
t5 = t5(1:n);
y5 = y5(1:n);

% Use common time base if nearly identical; otherwise use index-based overlap
if numel(t4) == numel(t5) && max(abs(t4(:) - t5(:))) < 1e-9
    t = t4;
else
    t = t4;
end

mask4 = local_get_full_window_body_mask(out4, n);
mask5 = local_get_full_window_body_mask(out5, n);
mask = mask4 & mask5 & isfinite(y4) & isfinite(y5);

idx = find(mask);
if isempty(idx)
    error('plot_ch5r_rmse_proxy_comparison:noBody', ...
        'No valid full-window body samples found for RMSE comparison.');
end

i1 = idx(1);
i2 = idx(end);

tb  = t(i1:i2);
y4b = y4(i1:i2);
y5b = y5(i1:i2);

fig = figure('Visible', 'off', 'Color', 'w');
plot(tb, y4b, 'LineWidth', 1.8); hold on;
plot(tb, y5b, 'LineWidth', 1.8); hold off;
grid on;

xlabel('Time (s)', 'Interpreter', 'tex');
ylabel('RMSE pos (km)', 'Interpreter', 'tex');
title(sprintf('R4-real vs R5-real: RMSE comparison (body-only, t=[%d,%d] s)', ...
    round(tb(1)), round(tb(end))), 'Interpreter', 'tex');

legend({'R4-real dynamic pair', 'R5-real predictive pair'}, ...
    'Location', 'best', 'Interpreter', 'tex');

save_path = fullfile(out_dir, ['plot_r5c_real_rmse_body_only_' stamp '.png']);
saveas(fig, save_path);
close(fig);

fprintf('[plot_ch5r_rmse_proxy_comparison] R4 source = %s\n', src4);
fprintf('[plot_ch5r_rmse_proxy_comparison] R5 source = %s\n', src5);
fprintf('[plot_ch5r_rmse_proxy_comparison] body-only range = [%d, %d] s\n', ...
    round(tb(1)), round(tb(end)));

out = struct();
out.save_path  = save_path;
out.t_start_s  = tb(1);
out.t_end_s    = tb(end);
out.i_start    = i1;
out.i_end      = i2;
out.num_points = numel(tb);
out.source_r4  = src4;
out.source_r5  = src5;
end

function [t_s, rmse_series, src] = local_extract_time_and_rmse(s, tag)
t_s = [];
rmse_series = [];
src = '';

% ---------- path 1: replay true RMSE ----------
cand = local_try_get(s, {'replay'});
if isstruct(cand)
    [t_s, rmse_series, ok] = local_read_rmse_block(cand);
    if ok
        src = 'replay';
        return;
    end
end

% ---------- path 2: diag true RMSE ----------
cand = local_try_get(s, {'diag'});
if isstruct(cand)
    [t_s, rmse_series, ok] = local_read_rmse_block(cand);
    if ok
        src = 'diag';
        return;
    end
end

% ---------- path 3: result.rmse_metrics ----------
cand = local_try_get(s, {'result','rmse_metrics'});
if isstruct(cand)
    [t_s, rmse_series, ok] = local_read_rmse_metrics(cand);
    if ok
        src = 'result.rmse_metrics';
        return;
    end
end

% ---------- path 4: legacy result / case / wininfo ----------
cand = local_try_get(s, {'result'});
if isstruct(cand)
    [t_s, rmse_series, ok, src_local] = local_read_legacy_proxy(cand, tag);
    if ok
        src = src_local;
        return;
    end
end

error('plot_ch5r_rmse_proxy_comparison:missingRMSE', ...
    'Cannot extract RMSE series from input struct for %s.', tag);
end

function [t_s, rmse_series, ok] = local_read_rmse_block(s)
t_s = [];
rmse_series = [];
ok = false;

t_cands = { ...
    't_s', 'time_s', 'time', 't' ...
    };

y_cands = { ...
    'rmse_pos_km', 'rmse_pos', 'rmse_km', 'rmse', ...
    'rmse_series', 'rmse_timeline' ...
    };

for i = 1:numel(t_cands)
    if isfield(s, t_cands{i})
        t_s = s.(t_cands{i});
        break;
    end
end
for i = 1:numel(y_cands)
    if isfield(s, y_cands{i})
        rmse_series = s.(y_cands{i});
        break;
    end
end

if isempty(rmse_series)
    return;
end
if isempty(t_s)
    t_s = (0:numel(rmse_series)-1).';
end

t_s = t_s(:);
rmse_series = rmse_series(:);

m = min(numel(t_s), numel(rmse_series));
t_s = t_s(1:m);
rmse_series = rmse_series(1:m);
ok = any(isfinite(rmse_series));
end

function [t_s, rmse_series, ok] = local_read_rmse_metrics(s)
t_s = [];
rmse_series = [];
ok = false;

if isfield(s, 'time_s')
    t_s = s.time_s;
elseif isfield(s, 't_s')
    t_s = s.t_s;
elseif isfield(s, 'time')
    t_s = s.time;
end

if isfield(s, 'rmse_pos_km')
    rmse_series = s.rmse_pos_km;
elseif isfield(s, 'rmse_proxy_timeline')
    rmse_series = s.rmse_proxy_timeline;
elseif isfield(s, 'rmse_proxy_series')
    rmse_series = s.rmse_proxy_series;
elseif isfield(s, 'rmse_timeline')
    rmse_series = s.rmse_timeline;
end

if isempty(rmse_series)
    return;
end
if isempty(t_s)
    t_s = (0:numel(rmse_series)-1).';
end

t_s = t_s(:);
rmse_series = rmse_series(:);

m = min(numel(t_s), numel(rmse_series));
t_s = t_s(1:m);
rmse_series = rmse_series(1:m);
ok = any(isfinite(rmse_series));
end

function [t_s, rmse_series, ok, src] = local_read_legacy_proxy(s, tag)
t_s = [];
rmse_series = [];
ok = false;
src = '';

% time path
case_block = [];
if isfield(s, 'case') && isstruct(s.case)
    case_block = s.case;
elseif isfield(s, 'target_case') && isstruct(s.target_case)
    case_block = s.target_case;
end

if ~isempty(case_block)
    if isfield(case_block, 't_s')
        t_s = case_block.t_s(:);
        fprintf('[plot_ch5r_rmse_proxy_comparison] %s: time path = case.t_s\n', tag);
    elseif isfield(case_block, 'time_s')
        t_s = case_block.time_s(:);
        fprintf('[plot_ch5r_rmse_proxy_comparison] %s: time path = case.time_s\n', tag);
    end
end

% lambda-like proxy path
if isfield(s, 'wininfo') && isstruct(s.wininfo)
    if isfield(s.wininfo, 'lambda_min')
        lam = s.wininfo.lambda_min(:);
        rmse_series = 1 ./ sqrt(max(lam, eps));
        fprintf('[plot_ch5r_rmse_proxy_comparison] %s: lambda-like path = wininfo.lambda_min (converted to 1/sqrt(.))\n', tag);
        src = 'legacy.wininfo.lambda_min';
    elseif isfield(s.wininfo, 'lambda_min_timeline')
        lam = s.wininfo.lambda_min_timeline(:);
        rmse_series = 1 ./ sqrt(max(lam, eps));
        fprintf('[plot_ch5r_rmse_proxy_comparison] %s: lambda-like path = wininfo.lambda_min_timeline (converted to 1/sqrt(.))\n', tag);
        src = 'legacy.wininfo.lambda_min_timeline';
    end
end

if isempty(rmse_series)
    return;
end
if isempty(t_s)
    t_s = (0:numel(rmse_series)-1).';
end

m = min(numel(t_s), numel(rmse_series));
t_s = t_s(1:m);
rmse_series = rmse_series(1:m);
ok = any(isfinite(rmse_series));
end

function mask = local_get_full_window_body_mask(s, n)
mask = false(n,1);

% explicit masks first
cand_paths = { ...
    {'result','rmse_metrics','valid_mask'}, ...
    {'result','rmse_metrics','full_window_mask'}, ...
    {'result','tracking','valid_mask'}, ...
    {'result','tracking','full_window_mask'}, ...
    {'diag','valid_mask'}, ...
    {'replay','valid_mask'}, ...
    {'result','bubble_metrics','valid_for_bubble'} ...
    };

for i = 1:numel(cand_paths)
    v = local_try_get(s, cand_paths{i});
    if ~isempty(v)
        v = logical(v(:));
        m = min(n, numel(v));
        mask(1:m) = v(1:m);
        if any(mask)
            return;
        end
    end
end

% infer from window length
Tw = local_try_get(s, {'cfg','ch5r','window','Tw_s'});
if isempty(Tw)
    Tw = local_try_get(s, {'cfg','window','Tw_s'});
end
if isempty(Tw)
    Tw = local_try_get(s, {'cfg','stage04','Tw_s'});
end
if isempty(Tw)
    Tw = 60;
end

Ts = local_try_get(s, {'cfg','ch5r','sim','Ts_s'});
if isempty(Ts)
    Ts = local_try_get(s, {'cfg','sim','Ts_s'});
end
if isempty(Ts)
    Ts = local_try_get(s, {'cfg','stage02','Ts_s'});
end
if isempty(Ts)
    Ts = 1;
end

half_span = floor((Tw / Ts) / 2);
i1 = 1 + half_span;
i2 = n - half_span;

if i2 >= i1
    mask(i1:i2) = true;
else
    mask(:) = true;
end
end

function v = local_try_get(s, path_cells)
v = [];
cur = s;
for i = 1:numel(path_cells)
    key = path_cells{i};
    if isstruct(cur) && isfield(cur, key)
        cur = cur.(key);
    else
        return;
    end
end
v = cur;
end
