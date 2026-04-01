function stats = summarize_outerA_mode_series(mode_series)
%SUMMARIZE_OUTERA_MODE_SERIES  Summarize safe/warn/trigger ratios.

if isstring(mode_series)
    ms = mode_series;
else
    ms = string(mode_series);
end

N = numel(ms);
safe_n = sum(ms == "safe");
warn_n = sum(ms == "warn");
trigger_n = sum(ms == "trigger");

stats = struct();
stats.num_steps = N;
stats.safe_count = safe_n;
stats.warn_count = warn_n;
stats.trigger_count = trigger_n;
stats.safe_ratio = safe_n / max(1, N);
stats.warn_ratio = warn_n / max(1, N);
stats.trigger_ratio = trigger_n / max(1, N);
end
