function stats = compute_schedule_statistics(refresh_mask, interval_schedule)
%COMPUTE_SCHEDULE_STATISTICS
assert(islogical(refresh_mask) && isvector(refresh_mask), 'refresh_mask invalid.');
assert(isnumeric(interval_schedule) && isvector(interval_schedule), 'interval_schedule invalid.');
assert(numel(refresh_mask) == numel(interval_schedule), 'length mismatch.');

refresh_idx = find(refresh_mask);
refresh_count = numel(refresh_idx);

if refresh_count >= 2
    realized_intervals = diff(refresh_idx);
else
    realized_intervals = [];
end

stats = struct();
stats.refresh_count = refresh_count;
stats.refresh_index = refresh_idx;
stats.realized_intervals = realized_intervals;
stats.mean_interval = mean(interval_schedule, 'omitnan');
stats.mean_realized_interval = mean(realized_intervals, 'omitnan');
stats.min_interval = min(interval_schedule);
stats.max_interval = max(interval_schedule);
stats.n_short = sum(interval_schedule == min(interval_schedule));

if isempty(realized_intervals)
    stats.n_early_refresh = 0;
else
    % "early refresh" here means realized interval shorter than the max declared interval
    stats.n_early_refresh = sum(realized_intervals < max(interval_schedule));
end
end
