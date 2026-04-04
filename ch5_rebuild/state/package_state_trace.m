function state_trace = package_state_trace(ch5case, wininfo, bubble)
%PACKAGE_STATE_TRACE  Package unified state trace for Chapter 5 R1/R2.
%
% Output fields:
%   state_trace.time_s
%   state_trace.lambda_min
%   state_trace.gamma_req
%   state_trace.is_bubble
%   state_trace.bubble_depth
%   state_trace.window_start_idx
%   state_trace.window_end_idx
%   state_trace.meta

if nargin < 3 || isempty(bubble)
    if nargin < 2 || isempty(wininfo)
        wininfo = eval_window_information(ch5case);
    end
    bubble = eval_bubble_state(ch5case, wininfo);
end

state_trace = struct();
state_trace.time_s = wininfo.time_s(:);
state_trace.lambda_min = bubble.lambda_min(:);
state_trace.gamma_req = ch5case.gamma_req;
state_trace.is_bubble = bubble.is_bubble(:);
state_trace.bubble_depth = bubble.bubble_depth(:);
state_trace.window_start_idx = wininfo.window_start_idx(:);
state_trace.window_end_idx = wininfo.window_end_idx(:);

state_trace.meta = struct();
state_trace.meta.phase_name = 'R1';
state_trace.meta.source = mfilename;
state_trace.meta.case_id = ch5case.target_case.case_id;
state_trace.meta.family = ch5case.target_case.family;
state_trace.meta.window_length_s = ch5case.window.length_s;
state_trace.meta.theta_Ns = ch5case.theta.Ns;
state_trace.meta.theta_h_km = ch5case.theta.h_km;
state_trace.meta.theta_i_deg = ch5case.theta.i_deg;
end
