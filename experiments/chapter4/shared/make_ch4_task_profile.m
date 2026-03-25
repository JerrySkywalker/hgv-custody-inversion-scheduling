function task_profile = make_ch4_task_profile()
task_profile = struct();

task_profile.nominal = struct();
task_profile.nominal.family_name = 'nominal';
task_profile.nominal.max_cases = 1;
task_profile.nominal.allowed_heading_offsets_deg = [];

task_profile.heading_minimal = struct();
task_profile.heading_minimal.family_name = 'heading';
task_profile.heading_minimal.max_cases = 3;
task_profile.heading_minimal.allowed_heading_offsets_deg = [];

task_profile.heading_zero_offset = struct();
task_profile.heading_zero_offset.family_name = 'heading';
task_profile.heading_zero_offset.max_cases = 1;
task_profile.heading_zero_offset.allowed_heading_offsets_deg = 0;

task_profile.heading_neg30_offset = struct();
task_profile.heading_neg30_offset.family_name = 'heading';
task_profile.heading_neg30_offset.max_cases = 1;
task_profile.heading_neg30_offset.allowed_heading_offsets_deg = -30;

task_profile.heading_pos30_offset = struct();
task_profile.heading_pos30_offset.family_name = 'heading';
task_profile.heading_pos30_offset.max_cases = 1;
task_profile.heading_pos30_offset.allowed_heading_offsets_deg = 30;
end
