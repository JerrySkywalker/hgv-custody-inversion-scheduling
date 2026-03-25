function export_profile = make_ch4_export_profile()
export_profile = struct();

export_profile.base_output_dir = fullfile('outputs', 'experiments', 'chapter4');

export_profile.mb = struct();
export_profile.mb.output_dir = fullfile(export_profile.base_output_dir, 'MB');
export_profile.mb.nominal_prefix = 'mb_nominal';
export_profile.mb.heading_prefix = 'mb_heading';
export_profile.mb.compare_prefix = 'mb_compare';

export_profile.validation = struct();
export_profile.validation.output_dir = fullfile(export_profile.base_output_dir, 'validation');
export_profile.validation.stage05_nominal_prefix = 'validate_stage05_nominal';
export_profile.validation.stage06_heading_prefix = 'validate_stage06_heading';
export_profile.validation.stage05_06_manifest_prefix = 'validate_against_stage05_06';

export_profile.figures = struct();
export_profile.figures.output_dir = fullfile(export_profile.base_output_dir, 'figures');
end
