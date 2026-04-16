function annotate_ch5r_bar_values(ax, barHandles, fmt, opts)
%ANNOTATE_CH5R_BAR_VALUES
% Add numeric labels to bar / stacked bar charts.

if nargin < 1 || isempty(ax)
    ax = gca;
end
if nargin < 2 || isempty(barHandles)
    return;
end
if nargin < 3 || isempty(fmt)
    fmt = '%.3g';
end
if nargin < 4 || isempty(opts)
    opts = struct();
end

if ~isfield(opts, 'mode') || isempty(opts.mode)
    opts.mode = 'above'; % 'above' | 'inside'
end
if ~isfield(opts, 'suffix') || isempty(opts.suffix)
    opts.suffix = '';
end
if ~isfield(opts, 'scale') || isempty(opts.scale)
    opts.scale = 1;
end
if ~isfield(opts, 'font_size') || isempty(opts.font_size)
    opts.font_size = 9;
end
if ~isfield(opts, 'color') || isempty(opts.color)
    opts.color = [0 0 0];
end
if ~isfield(opts, 'min_abs') || isempty(opts.min_abs)
    opts.min_abs = 0;
end
if ~isfield(opts, 'min_inside') || isempty(opts.min_inside)
    opts.min_inside = 0.08;
end
if ~isfield(opts, 'offset_frac') || isempty(opts.offset_frac)
    opts.offset_frac = 0.015;
end

yr = ylim(ax);
yspan = max(yr(2) - yr(1), eps);

for ib = 1:numel(barHandles)
    b = barHandles(ib);
    if ~isprop(b, 'XEndPoints') || ~isprop(b, 'YEndPoints')
        continue;
    end

    x = b.XEndPoints(:);
    yTop = b.YEndPoints(:);
    yData = b.YData(:);

    n = min([numel(x), numel(yTop), numel(yData)]);
    for k = 1:n
        v = yData(k);
        if ~isfinite(v) || abs(v) <= opts.min_abs
            continue;
        end

        txt = [sprintf(fmt, opts.scale * v) opts.suffix];

        if strcmpi(opts.mode, 'inside')
            if abs(v) >= opts.min_inside
                yText = yTop(k) - v/2;
                va = 'middle';
            else
                yText = yTop(k) + opts.offset_frac * yspan;
                va = 'bottom';
            end
        else
            yText = yTop(k) + opts.offset_frac * yspan;
            va = 'bottom';
        end

        text(ax, x(k), yText, txt, ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', va, ...
            'FontSize', opts.font_size, ...
            'Color', opts.color, ...
            'Interpreter', 'none');
    end
end
end
