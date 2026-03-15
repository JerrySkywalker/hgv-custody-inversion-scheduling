function style = milestone_common_plot_style()
%MILESTONE_COMMON_PLOT_STYLE Common styling tokens for milestone figures.

style = struct();
style.line_width = 1.8;
style.marker_size = 7;
style.font_size = 11;
style.threshold_line_style = '-.';
style.threshold_line_width = 1.2;
style.threshold_color = [0.25, 0.25, 0.25];
style.worst_marker = 'o';
style.marker_line_width = 1.3;
style.colors = [ ...
    0.09, 0.33, 0.55; ...
    0.79, 0.31, 0.16; ...
    0.20, 0.56, 0.30; ...
    0.60, 0.48, 0.15];
end
