function profile = make_ch5_minimal_profile()
%MAKE_CH5_MINIMAL_PROFILE Minimal Chapter 5 mission-loop profile.

grid_profile = make_ch4_design_grid_profile();

profile = struct();
profile.name = 'ch5_minimal_mission_loop';
profile.design_rows = grid_profile.validation_stage05.rows;
profile.heading_offsets_deg = [0, -30, 30];
profile.nominal_case_count = 1;
profile.output_dir = fullfile('outputs', 'experiments', 'chapter5', 'minimal');
end
