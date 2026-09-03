# Fixtures for tests/scheme-tests.R

`with_plugin_current/` and `with_plugin_pre/` are two real analysis directories from the
plugin's validation, reduced to what the generator reads: the workflow log in full, each script
cut to its comment lines and `set.seed()` calls, and every other file kept by name only at
zero bytes. `expected/WORKFLOW_current.md` is the accepted output for the first of them, and the
test compares against it ignoring the provenance timestamp. `loose/`, `emptylog/`, `nolog/`,
`fx_noheads/` and `fx_empty/` are the loose-log cases from the design specification.

The test writes its outputs to a temporary directory and nothing into this tree.
