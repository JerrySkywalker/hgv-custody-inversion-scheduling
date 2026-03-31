function alignment = match_outerA_events_to_bad_segments(phi_series, threshold, risk_state, lead_time_steps, window_steps)
%MATCH_OUTERA_EVENTS_TO_BAD_SEGMENTS
% Phase 6B-1:
%   1) bad event = bad window, not single-point dip
%   2) evaluate both trigger-only and warn-or-trigger alerts
%
% Inputs:
%   phi_series       : [N x 1]
%   threshold        : scalar
%   risk_state       : [N x 1], 0 safe / 1 warn / 2 trigger
%   lead_time_steps  : [N x 1]
%   window_steps     : scalar, future validation window
%
% Output:
%   alignment : struct

phi = phi_series(:);
state = risk_state(:);
lead  = lead_time_steps(:);
N = numel(phi);

if nargin < 5 || isempty(window_steps)
    window_steps = 20;
end

% ------------------------------------------------------------
% Build bad-window starts:
% a start k is considered "bad-window start" if there exists at least one
% phi<threshold inside [k, k+window_steps-1]
% then compress consecutive true samples into events
% ------------------------------------------------------------
bad_window_flag = false(N,1);
for k = 1:N
    j2 = min(N, k + window_steps - 1);
    bad_window_flag(k) = any(phi(k:j2) < threshold);
end

bad_starts = find(diff([0; bad_window_flag]) == 1);
bad_ends   = find(diff([bad_window_flag; 0]) == -1);

% Alert sets
is_trigger = (state == 2);
is_warn_or_trigger = (state >= 1);

trig_starts = find(diff([0; is_trigger]) == 1);
trig_ends   = find(diff([is_trigger; 0]) == -1);

awt_starts = find(diff([0; is_warn_or_trigger]) == 1);
awt_ends   = find(diff([is_warn_or_trigger; 0]) == -1);

alignment = struct();
alignment.bad_window_steps = window_steps;
alignment.bad_segment_count = numel(bad_starts);
alignment.bad_starts = bad_starts;
alignment.bad_ends = bad_ends;

alignment.trigger_only = local_eval_alert_set(bad_starts, bad_ends, trig_starts, trig_ends, lead);
alignment.warn_or_trigger = local_eval_alert_set(bad_starts, bad_ends, awt_starts, awt_ends, lead);
end

function out = local_eval_alert_set(bad_starts, bad_ends, alert_starts, alert_ends, lead)
num_bad = numel(bad_starts);
num_alert = numel(alert_starts);

bad_hit = false(num_bad,1);
alert_hit = false(num_alert,1);
lead_hits = [];

for i = 1:num_bad
    bs = bad_starts(i);

    idx = find(alert_starts <= bs & alert_ends >= max(1, bs-1), 1, 'first');

    if isempty(idx)
        idx2 = find(alert_starts < bs, 1, 'last');
        if ~isempty(idx2)
            a0 = alert_starts(idx2);
            if lead(a0) > 0 && (a0 + lead(a0)) >= bs
                idx = idx2;
            end
        end
    end

    if ~isempty(idx)
        bad_hit(i) = true;
        alert_hit(idx) = true;
        lt = bs - alert_starts(idx);
        if lt >= 0
            lead_hits(end+1,1) = lt; %#ok<AGROW>
        end
    end
end

num_hit = sum(bad_hit);
num_miss = num_bad - num_hit;
num_false_alarm = num_alert - sum(alert_hit);

out = struct();
out.event_count = num_alert;
out.hit_count = num_hit;
out.miss_count = num_miss;
out.false_alarm_count = num_false_alarm;

if num_bad > 0
    out.hit_rate = num_hit / num_bad;
    out.miss_rate = num_miss / num_bad;
else
    out.hit_rate = 0;
    out.miss_rate = 0;
end

if num_alert > 0
    out.false_alarm_rate = num_false_alarm / num_alert;
else
    out.false_alarm_rate = 0;
end

if isempty(lead_hits)
    out.mean_lead_time_steps = 0;
    out.max_lead_time_steps = 0;
else
    out.mean_lead_time_steps = mean(lead_hits);
    out.max_lead_time_steps = max(lead_hits);
end

out.alert_starts = alert_starts;
out.alert_ends = alert_ends;
out.bad_hit_flags = bad_hit;
out.alert_hit_flags = alert_hit;
out.lead_hits = lead_hits;
end
