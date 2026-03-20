function mb_safe_startup()
%MB_SAFE_STARTUP Initialize MB paths without breaking thread-based workers.

persistent startup_done
if ~isempty(startup_done) && startup_done
    return;
end

try
    startup();
catch ME
    message_text = lower(string(ME.message));
    if ~(contains(message_text, "matlabpath") || contains(message_text, "addpath"))
        rethrow(ME);
    end
end

startup_done = true;
end
