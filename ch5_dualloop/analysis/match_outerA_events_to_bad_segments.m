function alignment = match_outerA_events_to_bad_segments(phi_series, threshold, risk_state, lead_time_steps)
%MATCH_OUTERA_EVENTS_TO_BAD_SEGMENTS  Match outerA trigger events to bad phi segments.
%
% Inputs:
%   phi_series       : [N x 1]
%   threshold        : scalar
%   risk_state       : [N x 1], 0 safe / 1 warn / 2 trigger
%   lead_time_steps  : [N x 1], estimated lead time to next bad event
%
% Output:
%   alignment : struct with hit / miss / false-alarm style statistics

phi = phi_series(:);
state = risk_state(:);
lead = lead_time_steps(:);

is_bad = (phi < threshold);
is_trigger = (state == 2);

bad_starts = find(diff([0; is_bad]) == 1);
bad_ends   = find(diff([is_bad; 0]) == -1);

trig_starts = find(diff([0; is_trigger]) == 1);
trig_ends   = find(diff([is_trigger; 0]) == -1);

num_bad = numel(bad_starts);
num_trig = numel(trig_starts);

bad_hit = false(num_bad, 1);
trig_hit = false(num_trig, 1);
lead_hits = [];

for i = 1:num_bad
    bs = bad_starts(i);

    % Any trigger event that starts before bad-start and not too far away?
    idx = find(trig_starts <= bs & trig_ends >= max(1, bs-1), 1, 'first');

    if isempty(idx)
        % allow earlier trigger whose lead-time window reaches this bad start
        idx2 = find(trig_starts < bs, 1, 'last');
        if ~isempty(idx2)
            t0 = trig_starts(idx2);
            if lead(t0) > 0 && (t0 + lead(t0)) >= bs
                idx = idx2;
            end
        end
    end

    if ~isempty(idx)
        bad_hit(i) = true;
        trig_hit(idx) = true;

        lt = bs - trig_starts(idx);
        if lt >= 0
            lead_hits(end+1,1) = lt; %#ok<AGROW>
        end
    end
end

num_hit = sum(bad_hit);
num_miss = num_bad - num_hit;
num_false_alarm = num_trig - sum(trig_hit);

alignment = struct();
alignment.bad_segment_count = num_bad;
alignment.trigger_event_count = num_trig;
alignment.hit_count = num_hit;
alignment.miss_count = num_miss;
alignment.false_alarm_count = num_false_alarm;

if num_bad > 0
    alignment.hit_rate = num_hit / num_bad;
    alignment.miss_rate = num_miss / num_bad;
else
    alignment.hit_rate = 0;
    alignment.miss_rate = 0;
end

if num_trig > 0
    alignment.false_alarm_rate = num_false_alarm / num_trig;
else
    alignment.false_alarm_rate = 0;
end

if isempty(lead_hits)
    alignment.mean_lead_time_steps = 0;
    alignment.max_lead_time_steps = 0;
else
    alignment.mean_lead_time_steps = mean(lead_hits);
    alignment.max_lead_time_steps = max(lead_hits);
end

alignment.bad_starts = bad_starts;
alignment.bad_ends = bad_ends;
alignment.trigger_starts = trig_starts;
alignment.trigger_ends = trig_ends;
alignment.bad_hit_flags = bad_hit;
alignment.trigger_hit_flags = trig_hit;
alignment.lead_hits = lead_hits;
end
