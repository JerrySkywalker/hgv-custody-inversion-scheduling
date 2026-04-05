function selection_trace = build_selection_trace_from_r5_trace(raw_trace)
%BUILD_SELECTION_TRACE_FROM_R5_TRACE
% Normalize R5-real raw selection_trace into simple {step_index, source, best_pair} cells.

assert(iscell(raw_trace), 'raw_trace must be a cell.');

n_steps = numel(raw_trace);
selection_trace = cell(n_steps,1);

for k = 1:n_steps
    rec_in = raw_trace{k};
    rec_out = struct();
    rec_out.step_index = k;
    rec_out.source = "current_method";
    rec_out.best_pair = [];

    if ~isstruct(rec_in)
        selection_trace{k} = rec_out;
        continue;
    end

    pair = local_resolve_pair(rec_in);
    if ~isempty(pair)
        pair = pair(:).';
        if numel(pair) >= 2
            rec_out.best_pair = pair(1:2);
        end
    end

    selection_trace{k} = rec_out;
end
end

function pair = local_resolve_pair(rec)
pair = [];

candidate_fields = { ...
    'best_pair', ...
    'selected_pair', ...
    'pair', ...
    'sat_pair', ...
    'selected_sats'};

for i = 1:numel(candidate_fields)
    fn = candidate_fields{i};
    if isfield(rec, fn) && ~isempty(rec.(fn))
        pair = rec.(fn);
        return;
    end
end

% nested struct fallback
nested_fields = {'best_eval', 'selected_eval', 'sel_eval'};
for i = 1:numel(nested_fields)
    fn = nested_fields{i};
    if isfield(rec, fn) && isstruct(rec.(fn))
        pair = local_resolve_pair(rec.(fn));
        if ~isempty(pair)
            return;
        end
    end
end
end
