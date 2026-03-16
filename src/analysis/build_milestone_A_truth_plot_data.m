function plot_data = build_milestone_A_truth_plot_data(window_table, summary)
%BUILD_MILESTONE_A_TRUTH_PLOT_DATA Prepare Milestone A plotting arrays.

plot_data = struct();
plot_data.t0_s = window_table.t0_s;
plot_data.DG = window_table.DG_window;
plot_data.DA = window_table.DA_window;
plot_data.DT_bar = window_table.DT_bar_window;
plot_data.DT = window_table.DT_window;
plot_data.dt_max_window_s = window_table.dt_max_window_s;
plot_data.t0G_star_s = summary.t0G_star;
plot_data.t0A_star_s = summary.t0A_star;
plot_data.t0T_star_s = summary.t0T_star;
plot_data.Tw_s = summary.Tw_s;
plot_data.case_id = string(summary.case_id);
end
