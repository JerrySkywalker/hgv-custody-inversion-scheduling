function out = plot_ch5r_rmse_proxy_comparison(t_s, rmse_r4, rmse_r5, varargin)
% plot_ch5r_rmse_proxy_comparison
% R4-real vs R5-real Fisher-based RMSE proxy comparison.
% Display clipping is applied only for plotting, not for source data.

p = inputParser;
addParameter(p, 'save_path', '', @(x) ischar(x) || isstring(x));
addParameter(p, 'visible', 'off', @(x) ischar(x) || isstring(x));
addParameter(p, 'title_text', 'R4-real vs R5-real: Fisher-based RMSE proxy', @(x) ischar(x) || isstring(x));
addParameter(p, 'use_display_clip', true, @(x) islogical(x) || isnumeric(x));
addParameter(p, 'clip_percentile', 99.5, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 100);
addParameter(p, 'edge_exclude', 5, @(x) isnumeric(x) && isscalar(x) && x >= 0);
parse(p, varargin{:});
opt = p.Results;

t_s = t_s(:);
rmse_r4 = rmse_r4(:);
rmse_r5 = rmse_r5(:);

assert(numel(t_s) == numel(rmse_r4), 't_s and rmse_r4 size mismatch.');
assert(numel(t_s) == numel(rmse_r5), 't_s and rmse_r5 size mismatch.');

rmse_r4_plot = rmse_r4;
rmse_r5_plot = rmse_r5;

clip_info = struct( ...
    'enabled', logical(opt.use_display_clip), ...
    'percentile', opt.clip_percentile, ...
    'edge_exclude', opt.edge_exclude, ...
    'upper_r4', NaN, ...
    'upper_r5', NaN);

if opt.use_display_clip
    n = numel(t_s);
    i0 = max(1, 1 + opt.edge_exclude);
    i1 = min(n, n - opt.edge_exclude);
    if i0 <= i1
        core_idx = i0:i1;
    else
        core_idx = 1:n;
    end

    valid_r4 = isfinite(rmse_r4(core_idx)) & (rmse_r4(core_idx) > 0);
    valid_r5 = isfinite(rmse_r5(core_idx)) & (rmse_r5(core_idx) > 0);

    if any(valid_r4)
        clip_info.upper_r4 = prctile(rmse_r4(core_idx(valid_r4)), opt.clip_percentile);
        rmse_r4_plot(isfinite(rmse_r4_plot) & rmse_r4_plot > clip_info.upper_r4) = clip_info.upper_r4;
    end

    if any(valid_r5)
        clip_info.upper_r5 = prctile(rmse_r5(core_idx(valid_r5)), opt.clip_percentile);
        rmse_r5_plot(isfinite(rmse_r5_plot) & rmse_r5_plot > clip_info.upper_r5) = clip_info.upper_r5;
    end
end

fig = figure('Visible', char(opt.visible));
plot(t_s, rmse_r4_plot, 'LineWidth', 1.5); hold on;
plot(t_s, rmse_r5_plot, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('RMSE proxy');

if opt.use_display_clip
    title(sprintf('%s (display-clipped @ p%.1f)', char(opt.title_text), opt.clip_percentile));
else
    title(char(opt.title_text));
end

legend({'R4-real dynamic pair', 'R5-real predictive pair'}, 'Location', 'best');

out = struct();
out.figure = fig;
out.clip_info = clip_info;
out.t_s = t_s;
out.rmse_r4_raw = rmse_r4;
out.rmse_r5_raw = rmse_r5;
out.rmse_r4_plot = rmse_r4_plot;
out.rmse_r5_plot = rmse_r5_plot;
out.save_path = '';

if strlength(string(opt.save_path)) > 0
    saveas(fig, char(opt.save_path));
    out.save_path = char(opt.save_path);
end
end
