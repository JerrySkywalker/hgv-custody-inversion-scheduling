function mg = compute_mg_series(result, cfg)
%COMPUTE_MG_SERIES  Normalized geometry/coverage proxy from selected satellite count.

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

max_track_sats = cfg.ch5.max_track_sats;
mg = result.tracking_sat_count(:) / max_track_sats;
mg = max(0, min(1, mg));
end
