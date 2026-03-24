function info = benchmark_collect_system_info()
    %BENCHMARK_COLLECT_SYSTEM_INFO Collect host, MATLAB, and git metadata for benchmark records.

    info = struct();
    info.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
    info.matlab_version = version;
    info.matlab_release = version('-release');
    info.computer = computer;
    info.hostname = local_get_hostname();
    info.git_commit = local_get_git_commit();
    info.git_branch = local_get_git_branch();
    info.num_cores = feature('numcores');
    info.parallel_toolbox = license('test', 'Distrib_Computing_Toolbox');
end

function out = local_get_hostname()
    out = '';
    try
        [status, txt] = system('hostname');
        if status == 0
            out = strtrim(txt);
        end
    catch
        out = '';
    end
end

function out = local_get_git_commit()
    out = '';
    try
        [status, txt] = system('git rev-parse HEAD');
        if status == 0
            out = strtrim(txt);
        end
    catch
        out = '';
    end
end

function out = local_get_git_branch()
    out = '';
    try
        [status, txt] = system('git rev-parse --abbrev-ref HEAD');
        if status == 0
            out = strtrim(txt);
        end
    catch
        out = '';
    end
end
