function cmp = benchmark_compare_results(serial_result, candidate_result, compare_opts)
    %BENCHMARK_COMPARE_RESULTS Compare two MATLAB values with field ignores and tolerances.

    if nargin < 3 || isempty(compare_opts)
        compare_opts = struct();
    end

    compare_opts = local_normalize_compare_opts(compare_opts);

    state = struct();
    state.max_abs_diff = 0;
    state.max_rel_diff = 0;
    state.messages = {};

    state = local_compare_value(serial_result, candidate_result, 'result', compare_opts, state);

    cmp = struct();
    cmp.passed = isempty(state.messages);
    cmp.max_abs_diff = state.max_abs_diff;
    cmp.max_rel_diff = state.max_rel_diff;
    cmp.message_count = numel(state.messages);
    cmp.messages = state.messages(:);
    if cmp.passed
        cmp.summary = 'Outputs match within configured tolerance.';
    else
        cmp.summary = strjoin(state.messages(:)', ' | ');
    end
end

function opts = local_normalize_compare_opts(opts)
    if ~isfield(opts, 'abs_tol') || isempty(opts.abs_tol)
        opts.abs_tol = 1e-12;
    end
    if ~isfield(opts, 'rel_tol') || isempty(opts.rel_tol)
        opts.rel_tol = 1e-9;
    end
    if ~isfield(opts, 'ignored_fields') || isempty(opts.ignored_fields)
        opts.ignored_fields = {};
    end
    opts.ignored_fields = cellstr(string(opts.ignored_fields));
end

function state = local_compare_value(a, b, path_str, opts, state)
    if isstruct(a) && isstruct(b)
        state = local_compare_struct(a, b, path_str, opts, state);
        return;
    end

    if iscell(a) && iscell(b)
        if ~isequal(size(a), size(b))
            state.messages{end + 1} = sprintf('%s size mismatch.', path_str);
            return;
        end
        for iCell = 1:numel(a)
            state = local_compare_value(a{iCell}, b{iCell}, sprintf('%s{%d}', path_str, iCell), opts, state);
        end
        return;
    end

    if isnumeric(a) && isnumeric(b)
        state = local_compare_numeric(a, b, path_str, opts, state);
        return;
    end

    if islogical(a) && islogical(b)
        if ~isequal(a, b)
            state.messages{end + 1} = sprintf('%s logical mismatch.', path_str);
        end
        return;
    end

    if isstring(a) || ischar(a) || isstring(b) || ischar(b)
        if ~strcmp(string(a), string(b))
            state.messages{end + 1} = sprintf('%s text mismatch.', path_str);
        end
        return;
    end

    if ~isequaln(a, b)
        state.messages{end + 1} = sprintf('%s value mismatch (%s vs %s).', ...
            path_str, class(a), class(b));
    end
end

function state = local_compare_struct(a, b, path_str, opts, state)
    a_fields = setdiff(fieldnames(a), opts.ignored_fields);
    b_fields = setdiff(fieldnames(b), opts.ignored_fields);

    missing_in_b = setdiff(a_fields, b_fields);
    missing_in_a = setdiff(b_fields, a_fields);

    for iField = 1:numel(missing_in_b)
        state.messages{end + 1} = sprintf('%s.%s missing in candidate.', path_str, missing_in_b{iField});
    end
    for iField = 1:numel(missing_in_a)
        state.messages{end + 1} = sprintf('%s.%s missing in serial baseline.', path_str, missing_in_a{iField});
    end

    common_fields = intersect(a_fields, b_fields, 'stable');
    for iField = 1:numel(common_fields)
        field_name = common_fields{iField};
        state = local_compare_value(a.(field_name), b.(field_name), ...
            sprintf('%s.%s', path_str, field_name), opts, state);
    end
end

function state = local_compare_numeric(a, b, path_str, opts, state)
    if ~isequal(size(a), size(b))
        state.messages{end + 1} = sprintf('%s numeric size mismatch.', path_str);
        return;
    end

    if isempty(a) && isempty(b)
        return;
    end

    same_nan = isnan(a) & isnan(b);
    same_inf = isinf(a) & isinf(b) & (sign(a) == sign(b));

    diff_val = abs(a - b);
    ref_val = max(abs(a), abs(b));
    ref_val(ref_val == 0) = 1;
    rel_val = diff_val ./ ref_val;
    diff_val(same_nan | same_inf) = 0;
    rel_val(same_nan | same_inf) = 0;
    ref_val(same_nan | same_inf) = 1;

    local_abs = max(diff_val(:));
    local_rel = max(rel_val(:));

    if ~isempty(local_abs)
        state.max_abs_diff = max(state.max_abs_diff, local_abs);
        state.max_rel_diff = max(state.max_rel_diff, local_rel);
    end

    pass_mask = diff_val <= opts.abs_tol + opts.rel_tol .* ref_val;
    pass_mask(same_nan | same_inf) = true;
    if ~all(pass_mask(:))
        first_bad = find(~pass_mask, 1, 'first');
        state.messages{end + 1} = sprintf('%s numeric mismatch at linear index %d (abs=%.3e, rel=%.3e).', ...
            path_str, first_bad, diff_val(first_bad), rel_val(first_bad));
    end
end
