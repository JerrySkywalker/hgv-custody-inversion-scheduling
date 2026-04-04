function fig_path = plot_static_failure_case(result, out_dir, stamp)
%PLOT_STATIC_FAILURE_CASE  Plot bubble flag over time for static-hold baseline.

if nargin < 2 || isempty(out_dir)
    out_dir = pwd;
end
if nargin < 3 || isempty(stamp)
    stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
end

state_trace = result.state_trace;

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

fig = figure('Visible', 'off');
stairs(state_trace.time_s, double(state_trace.is_bubble), 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Bubble Flag');
title('Static-Hold Failure Case');
ylim([-0.1 1.1]);
grid on

fig_path = fullfile(out_dir, ['plot_static_failure_case_' stamp '.png']);
saveas(fig, fig_path);
close(fig);
end
