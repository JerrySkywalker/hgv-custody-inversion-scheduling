function fig = plot_envelope_curve(x_values, y_values, plot_spec)
%PLOT_ENVELOPE_CURVE Minimal line plotting helper.

if nargin < 3
    plot_spec = struct();
end

title_text = local_get(plot_spec, 'title', '');
x_label = local_get(plot_spec, 'x_label', 'Ns');
y_label = local_get(plot_spec, 'y_label', 'Metric');
visible_mode = local_get(plot_spec, 'visible', 'on');
marker = local_get(plot_spec, 'marker', 'o-');

fig = figure('Visible', visible_mode);
plot(x_values, y_values, marker, 'LineWidth', 1.2);
grid on;
xlabel(x_label);
ylabel(y_label);
title(title_text);
end

function v = local_get(s, f, d)
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end
end
