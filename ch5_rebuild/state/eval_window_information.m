function wininfo = eval_window_information(ch5case, selection_trace)
%EVAL_WINDOW_INFORMATION
% Compute rolling/centered window information with explicit validity mask.
%
% Current supported mode:
%   - centered_full_only

if nargin < 2 || isempty(selection_trace)
    error('selection_trace is required.');
end

t_s = ch5case.t_s(:);
N = numel(t_s);
L = ch5case.window.length_steps;
mode_name = ch5case.window.mode;

lambda_min = nan(N,1);
lambda_trace = nan(N,1);
window_start_idx = nan(N,1);
window_end_idx = nan(N,1);
window_count = zeros(N,1);
is_full_window = false(N,1);
valid_for_bubble = false(N,1);
has_nonzero_input = false(N,1);

J_bank = cell(N,1);
for k = 1:N
    if k <= numel(selection_trace) && isstruct(selection_trace{k}) && isfield(selection_trace{k}, 'J_pair') ...
            && ~isempty(selection_trace{k}.J_pair)
        J_bank{k} = selection_trace{k}.J_pair;
    else
        J_bank{k} = zeros(3,3);
    end
end

switch lower(mode_name)
    case 'centered_full_only'
        left_steps = ch5case.window.left_steps;
        right_steps = ch5case.window.right_steps;

        for k = 1:N
            s0 = k - left_steps;
            s1 = k + right_steps;

            if s0 < 1 || s1 > N
                window_start_idx(k) = max(1, s0);
                window_end_idx(k) = min(N, s1);
                window_count(k) = window_end_idx(k) - window_start_idx(k) + 1;
                is_full_window(k) = false;
                valid_for_bubble(k) = false;
                continue;
            end

            window_start_idx(k) = s0;
            window_end_idx(k) = s1;
            window_count(k) = s1 - s0 + 1;
            is_full_window(k) = (window_count(k) == L);
            valid_for_bubble(k) = is_full_window(k);

            Y = zeros(3,3);
            nonzero_flag = false;
            for j = s0:s1
                J = J_bank{j};
                Y = Y + J;
                if ~nonzero_flag && any(J(:) ~= 0)
                    nonzero_flag = true;
                end
            end

            has_nonzero_input(k) = nonzero_flag;

            eigvals = eig((Y + Y.')/2);
            lambda_min(k) = min(real(eigvals));
            lambda_trace(k) = trace(Y);
        end

    otherwise
        error('Unsupported window mode: %s', mode_name);
end

wininfo = struct();
wininfo.t_s = t_s;
wininfo.time_s = t_s;
wininfo.lambda_min = lambda_min;
wininfo.lambda_trace = lambda_trace;
wininfo.window_start_idx = window_start_idx;
wininfo.window_end_idx = window_end_idx;
wininfo.window_count = window_count;
wininfo.is_full_window = is_full_window;
wininfo.valid_for_bubble = valid_for_bubble;
wininfo.has_nonzero_input = has_nonzero_input;
wininfo.window_mode = mode_name;
wininfo.window_length_steps = L;
wininfo.window_length_s = ch5case.window.length_s;
end
