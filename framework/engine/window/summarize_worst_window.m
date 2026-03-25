function summary = summarize_worst_window(window_case)
%SUMMARIZE_WORST_WINDOW Summarize a worst-window scan result.
% Input:
%   window_case : Stage04-style window scan result
%
% Output:
%   summary     : summary struct with lambda/t0 statistics

summary = legacy_summarize_window_case_stage04_impl(window_case);
end
