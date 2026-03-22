function write_mb_plot_domain_sidecar(file_path, plot_domain_mode, x_domain_origin, plot_xlim_ns, extra_fields)
%WRITE_MB_PLOT_DOMAIN_SIDECAR Write lightweight plot-domain metadata sidecar.

if nargin < 5 || isempty(extra_fields)
    extra_fields = struct();
end

payload = struct();
payload.plot_domain_mode = string(plot_domain_mode);
payload.x_domain_origin = string(x_domain_origin);
if isnumeric(plot_xlim_ns) && numel(plot_xlim_ns) == 2 && all(isfinite(plot_xlim_ns))
    payload.x_min_rendered = double(plot_xlim_ns(1));
    payload.x_max_rendered = double(plot_xlim_ns(2));
else
    payload.x_min_rendered = NaN;
    payload.x_max_rendered = NaN;
end

extra_names = fieldnames(extra_fields);
for idx = 1:numel(extra_names)
    payload.(extra_names{idx}) = extra_fields.(extra_names{idx});
end

sidecar_path = local_sidecar_path(file_path);
if exist(sidecar_path, 'file') == 2
    try
        existing = jsondecode(fileread(sidecar_path));
        existing_names = fieldnames(existing);
        for idx = 1:numel(existing_names)
            payload.(existing_names{idx}) = existing.(existing_names{idx});
        end
        payload.plot_domain_mode = string(plot_domain_mode);
        payload.x_domain_origin = string(x_domain_origin);
        if isnumeric(plot_xlim_ns) && numel(plot_xlim_ns) == 2 && all(isfinite(plot_xlim_ns))
            payload.x_min_rendered = double(plot_xlim_ns(1));
            payload.x_max_rendered = double(plot_xlim_ns(2));
        end
    catch
        % Keep the new payload when an existing sidecar is unreadable.
    end
end

fid = fopen(sidecar_path, 'w');
if fid < 0
    warning('MB:PlotSidecar', 'Failed to write plot-domain sidecar: %s', sidecar_path);
    return;
end
cleanup_obj = onCleanup(@() fclose(fid)); %#ok<NASGU>
fprintf(fid, '%s', jsonencode(payload));
end

function sidecar_path = local_sidecar_path(file_path)
[folder, stem] = fileparts(file_path);
sidecar_path = fullfile(folder, stem + ".meta.json");
end
