function cfg = default_ch5_params()
%DEFAULT_CH5_PARAMS  Chapter 5 default parameters for isolated phase development.
%
% Phase 0 target:
%   - no modification to chapter 4 code
%   - isolated output root under outputs/cpt5/<phase>
%   - only smoke-test level scene summary

cfg = struct();

cfg.phase_name = 'phase0';
cfg.output_root = fullfile(pwd, 'outputs', 'cpt5', cfg.phase_name);

cfg.time = struct();
cfg.time.t0 = 0;
cfg.time.tf = 500;
cfg.time.dt = 1;

cfg.target = struct();
cfg.target.name = 'HGV_Demo';
cfg.target.model = 'placeholder';

cfg.constellation = struct();
cfg.constellation.name = 'Walker_Demo';
cfg.constellation.altitude_km = 1000;
cfg.constellation.inclination_deg = 90;
cfg.constellation.num_planes = 6;
cfg.constellation.sats_per_plane = 4;

cfg.sensor = struct();
cfg.sensor.name = 'IR_Demo';
cfg.sensor.max_range_km = 5000;
cfg.sensor.fov_deg = 5;

cfg.notes = struct();
cfg.notes.phase = 'Phase0 smoke only';
cfg.notes.chapter4_code_modified = false;
end
