function base = manual_smoke_stage09_phase1_metric_views_cached()
%MANUAL_SMOKE_STAGE09_PHASE1_METRIC_VIEWS_CACHED
% Reuse a cached Phase1-B base in current MATLAB session.

    persistent BASE_CACHE

    if isempty(BASE_CACHE)
        fprintf('[PHASE1-B-CACHED] No in-session cache found. Build once.\n');
        BASE_CACHE = manual_smoke_stage09_phase1_metric_views();
    else
        fprintf('[PHASE1-B-CACHED] Reusing in-session base cache. No search rerun.\n');
    end

    base = BASE_CACHE;
end
