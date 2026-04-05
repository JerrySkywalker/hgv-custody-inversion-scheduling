function stats = compute_schedule_statistics(refresh_mask, interval_schedule)
%COMPUTE_SCHEDULE_STATISTICS
assert(islogical(refresh_mask) && isvector(refresh_mask), 'refresh_mask invalid.');
assert(isnumeric(interval_schedule) && isvector(interval_schedule), 'interval_schedule invalid.');
assert(numel(refresh_mask) == numel(interval_schedule), 'length mismatch.');

refresh_idx = find(refresh_mask);
refresh_count = numel(refresh_idx);

stats = struct();
stats.refresh_count = refresh_count;
stats.mean_interval = mean(interval_schedule, 'omitnan');
stats.min_interval = min(interval_schedule);
stats.max_interval = max(interval_schedule);
stats.n_short = sum(interval_schedule == min(interval_schedule));
stats.n_mid = NaN;
stats.n_long = NaN;
end
