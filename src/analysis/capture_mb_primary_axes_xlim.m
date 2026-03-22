function xlim_values = capture_mb_primary_axes_xlim(fig)
%CAPTURE_MB_PRIMARY_AXES_XLIM Capture x-limits from the main data axes.

xlim_values = [NaN, NaN];
if isempty(fig) || ~ishandle(fig)
    return;
end

ax = local_pick_primary_axes(fig);
if isempty(ax) || ~ishandle(ax)
    return;
end

try
    values = xlim(ax);
    if numel(values) == 2 && all(isfinite(values))
        xlim_values = reshape(values, 1, []);
    end
catch
    xlim_values = [NaN, NaN];
end
end

function ax_best = local_pick_primary_axes(fig)
ax_best = [];
axes_list = findall(fig, 'Type', 'axes');
if isempty(axes_list)
    current_ax = get(fig, 'CurrentAxes');
    if ~isempty(current_ax) && ishandle(current_ax)
        ax_best = current_ax;
    end
    return;
end

best_score = -inf;
for idx = 1:numel(axes_list)
    ax = axes_list(idx);
    if ~ishandle(ax)
        continue;
    end
    tag_value = string(local_safe_get(ax, 'Tag', ""));
    if contains(lower(tag_value), "legend") || contains(lower(tag_value), "colorbar")
        continue;
    end

    score = 0;
    visible_value = string(local_safe_get(ax, 'Visible', "on"));
    if visible_value == "on"
        score = score + 1000;
    end

    position_value = local_safe_get(ax, 'Position', []);
    if isnumeric(position_value) && numel(position_value) >= 4
        score = score + double(position_value(3) * position_value(4));
    end

    child_count = numel(allchild(ax));
    score = score + 10 * child_count;

    if score > best_score
        best_score = score;
        ax_best = ax;
    end
end

if isempty(ax_best)
    current_ax = get(fig, 'CurrentAxes');
    if ~isempty(current_ax) && ishandle(current_ax)
        ax_best = current_ax;
    elseif ~isempty(axes_list)
        ax_best = axes_list(1);
    end
end
end

function value = local_safe_get(h, prop_name, fallback)
try
    value = get(h, prop_name);
    if isempty(value)
        value = fallback;
    end
catch
    value = fallback;
end
end
