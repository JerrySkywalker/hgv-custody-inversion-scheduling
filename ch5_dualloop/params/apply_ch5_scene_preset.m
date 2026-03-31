function cfg = apply_ch5_scene_preset(cfg, scene_name)
%APPLY_CH5_SCENE_PRESET  Apply chapter-5 scene preset on top of project defaults.
%
% Supported presets:
%   - stress96 : stage03-aligned 96-sat pressure scene
%   - ref128   : same (i,P,h) but T=16 => 128 sats, as static-reference-aligned scene

if nargin < 1 || isempty(cfg)
    error('cfg is required.');
end
if nargin < 2 || isempty(scene_name)
    scene_name = 'stress96';
end

scene_name = lower(string(scene_name));

switch scene_name
    case "stress96"
        cfg.constellation.name = 'Walker_Stress96';
        cfg.constellation.altitude_km = cfg.stage03.h_km;
        cfg.constellation.inclination_deg = cfg.stage03.i_deg;
        cfg.constellation.num_planes = cfg.stage03.P;
        cfg.constellation.sats_per_plane = cfg.stage03.T;
        cfg.constellation.phase_factor = cfg.stage03.F;

        cfg.sensor.name = 'IR_Stress96';
        cfg.sensor.max_range_km = cfg.stage03.max_range_km;
        cfg.sensor.fov_deg = 5;

    case "ref128"
        cfg.constellation.name = 'Walker_Ref128';
        cfg.constellation.altitude_km = cfg.stage03.h_km;
        cfg.constellation.inclination_deg = cfg.stage03.i_deg;
        cfg.constellation.num_planes = cfg.stage03.P;
        cfg.constellation.sats_per_plane = 16;
        cfg.constellation.phase_factor = cfg.stage03.F;

        cfg.sensor.name = 'IR_Ref128';
        cfg.sensor.max_range_km = cfg.stage03.max_range_km;
        cfg.sensor.fov_deg = 5;

    otherwise
        error('Unsupported chapter-5 scene preset: %s', scene_name);
end

cfg.ch5.scene_preset = char(scene_name);
end
