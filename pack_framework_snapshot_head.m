function out = pack_framework_snapshot_head()
opts = struct();
opts.snapshot_name = 'framework_snapshot_head';
opts.scope = 'head';
opts.code_only = false;
opts.include_outputs = true;
opts.include_chapter5 = false;
opts.include_legacy = false;

out = pack_framework_snapshot_core(opts);
end
