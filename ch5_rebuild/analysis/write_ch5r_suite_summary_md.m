function md_file = write_ch5r_suite_summary_md(output_dir, stats, tag)
%WRITE_CH5R_SUITE_SUMMARY_MD
% Write a compact markdown summary for Phase 4A.

if nargin < 3 || isempty(tag)
    tag = char(datetime('now','Format','yyyyMMdd_HHmmss'));
end

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

md_file = fullfile(output_dir, ['multicase_summary_' tag '.md']);

lines = {};
lines{end+1} = '# Chapter 5 multicase summary';
lines{end+1} = '';
lines{end+1} = ['Tag: `', tag, '`'];
lines{end+1} = '';
lines{end+1} = '## Metrics';
lines{end+1} = '';
for i = 1:numel(stats.metrics)
    lines{end+1} = ['- ', stats.metrics{i}];
end
lines{end+1} = '';
lines{end+1} = '## Overall summary';
lines{end+1} = '';
lines{end+1} = local_table_to_md(stats.overall);
lines{end+1} = '';
lines{end+1} = '## By-family summary';
lines{end+1} = '';
lines{end+1} = local_table_to_md(stats.by_family);

fid = fopen(md_file, 'w');
assert(fid >= 0, 'Failed to open markdown file for writing.');
for i = 1:numel(lines)
    fprintf(fid, '%s\n', lines{i});
end
fclose(fid);
end

function md = local_table_to_md(T)
if isempty(T)
    md = '_empty_';
    return;
end

vars = T.Properties.VariableNames;
header = ['| ' strjoin(vars, ' | ') ' |'];
sep = ['| ' strjoin(repmat({'---'}, 1, numel(vars)), ' | ') ' |'];

rows = cell(height(T),1);
for i = 1:height(T)
    vals = cell(1, numel(vars));
    for j = 1:numel(vars)
        x = T{i,j};
        if isstring(x)
            vals{j} = char(x);
        elseif iscell(x)
            vals{j} = char(string(x{1}));
        elseif isnumeric(x)
            if isscalar(x)
                vals{j} = num2str(x, '%.6g');
            else
                vals{j} = '[array]';
            end
        elseif islogical(x)
            vals{j} = char(string(x));
        else
            vals{j} = char(string(x));
        end
    end
    rows{i} = ['| ' strjoin(vals, ' | ') ' |'];
end

md = strjoin([{header}; {sep}; rows], newline);
end
