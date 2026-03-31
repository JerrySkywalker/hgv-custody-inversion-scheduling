function satbank = build_ch5_satbank_from_stage03_engine(cfg, t_s)
%BUILD_CH5_SATBANK_FROM_STAGE03_ENGINE  Build chapter 5 satellite bank using Stage03 engine.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end
if nargin < 2 || isempty(t_s)
    error('Time axis t_s is required.');
end

requiredFns = { ...
    'build_single_layer_walker_stage03', ...
    'propagate_constellation_stage03'};

for i = 1:numel(requiredFns)
    if exist(requiredFns{i}, 'file') ~= 2
        error('Required Stage03 function not found on path: %s', requiredFns{i});
    end
end

% Build a local cfg copy with chapter-5 constellation settings mapped into stage03.
cfg_local = cfg;

cfg_local.stage03.h_km = cfg.constellation.altitude_km;
cfg_local.stage03.i_deg = cfg.constellation.inclination_deg;
cfg_local.stage03.P = cfg.constellation.num_planes;
cfg_local.stage03.T = cfg.constellation.sats_per_plane;
cfg_local.stage03.F = cfg.constellation.phase_factor;

walker = build_single_layer_walker_stage03(cfg_local);
satbank = propagate_constellation_stage03(walker, t_s);

satbank.meta = struct();
satbank.meta.source = 'stage03_engine';
satbank.meta.generated_by = mfilename;
satbank.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
end
