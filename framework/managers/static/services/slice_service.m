function slice_result = slice_service(truth_result, slice_spec)
if nargin < 1 || ~isstruct(truth_result) || ~isfield(truth_result, 'table')
    error('slice_service:InvalidInput', ...
        'truth_result with table field is required.');
end

if nargin < 2 || ~isstruct(slice_spec)
    slice_spec = struct();
end

slice_mode = 'PT';
if isfield(slice_spec, 'mode') && ~isempty(slice_spec.mode)
    slice_mode = upper(string(slice_spec.mode));
end

feasible_only = false;
if isfield(slice_spec, 'feasible_only') && ~isempty(slice_spec.feasible_only)
    feasible_only = logical(slice_spec.feasible_only);
end

sort_by = '';
if isfield(slice_spec, 'sort_by') && ~isempty(slice_spec.sort_by)
    sort_by = string(slice_spec.sort_by);
end

tbl = truth_result.table;

if feasible_only
    tbl = tbl(tbl.is_feasible, :);
end

switch char(slice_mode)
    case 'PT'
        vars = {'design_id','P','T','Ns','joint_margin','is_feasible','fail_reason'};
    case 'HI'
        vars = {'design_id','h_km','i_deg','Ns','joint_margin','is_feasible','fail_reason'};
    otherwise
        error('slice_service:UnsupportedMode', ...
            'Unsupported slice mode: %s', slice_mode);
end

slice_table = tbl(:, vars);

switch char(sort_by)
    case 'Ns_asc'
        slice_table = sortrows(slice_table, {'Ns','joint_margin'}, {'ascend','descend'});
    case 'joint_margin_desc'
        slice_table = sortrows(slice_table, {'joint_margin','Ns'}, {'descend','ascend'});
    case ''
        % no sort
    otherwise
        error('slice_service:UnsupportedSort', ...
            'Unsupported sort_by option: %s', sort_by);
end

slice_result = struct();
slice_result.mode = char(slice_mode);
slice_result.feasible_only = feasible_only;
slice_result.sort_by = char(sort_by);
slice_result.table = slice_table;
slice_result.row_count = height(slice_table);
slice_result.meta = struct('status', 'ok');
end
