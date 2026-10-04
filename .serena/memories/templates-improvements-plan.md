# Template Sensors: Open Cleanup

Earlier review items (daily forecast type, unit mismatch, waste calendar trigger,
day progress after sunset, forecast length guards) are implemented in
`modules/automation/home-assistant/templates.nix`.

## Open (optional)
**Battery icon template repetition**: the battery icon Jinja logic is duplicated
across sensors in `templates.nix` (see the `mdi:battery-outline` branches).
Extract to a shared Nix helper or keep as-is for simplicity.
