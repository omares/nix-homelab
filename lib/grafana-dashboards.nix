# Grafana Dashboard Provisioning Utilities
#
# Adapted from: https://github.com/blackheaven/grafana-dashboards.nix
# Original author: Gautier DI FOLCO (blackheaven)
# License: MIT
#
# This module provides utilities for provisioning Grafana dashboards from
# grafana.com. The key insight is using pure Nix evaluation to transform
# dashboard JSON files, avoiding runtime dependencies like jq.

{ pkgs, lib }:
rec {
  # Downloads a dashboard JSON from grafana.com's API.
  # Using fetchurl with a hash ensures reproducible builds.
  fetchDashboard =
    {
      name,
      sha256,
      id,
      version,
    }:
    pkgs.fetchurl {
      inherit sha256;
      name = "grafana-dashboard-${name}";
      url = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString version}/download";
    };

  # Downloads a dashboard JSON from any URL.
  # Use this for dashboards not hosted on grafana.com (e.g., GitHub repos).
  fetchDashboardFromUrl =
    {
      name,
      sha256,
      url,
    }:
    pkgs.fetchurl {
      inherit sha256 url;
      name = "grafana-dashboard-${name}";
    };

  # Transforms dashboard JSON using Nix functions instead of jq.
  # This avoids adding jq as a build dependency and allows transformations
  # to be composed using standard Nix function composition.
  transformDashboard =
    {
      name,
      path,
      transform,
    }:
    builtins.toFile name (builtins.toJSON (transform (builtins.fromJSON (builtins.readFile path))));

  # Creates a dashboard provider entry for Grafana's provisioning system.
  # Grafana expects dashboards in a directory, so we copy the JSON file
  # into a derivation that can be referenced by the provider path.
  dashboardEntry =
    {
      name,
      path,
      transform ? null,
    }:
    let
      finalPath = if transform == null then path else transformDashboard { inherit name path transform; };
      dashboardDir = pkgs.runCommand "grafana-dashboard-${name}" { } ''
        mkdir -p $out
        cp ${finalPath} $out/${name}.json
      '';
    in
    {
      inherit name;
      options.path = dashboardDir;
    };

  # Replaces datasource template variables (e.g., $DS_PROMETHEUS) with
  # actual datasource UIDs. Dashboards from grafana.com use placeholder
  # variables that must match your provisioned datasource UIDs.
  replaceDatasources =
    replacements: dashboard:
    let
      # Handle both $VAR and ${VAR} syntax used in Grafana dashboards
      fromStrings = builtins.concatMap (r: [
        "\$${r.key}"
        "\${${r.key}}"
      ]) replacements;
      toStrings = builtins.concatMap (r: [
        r.value
        r.value
      ]) replacements;
      go =
        x:
        if builtins.isString x then
          builtins.replaceStrings fromStrings toStrings x
        else if builtins.isList x then
          map go x
        else if builtins.isAttrs x then
          lib.mapAttrs (_: go) x
        else
          x;
    in
    go dashboard;

  # Sets the dashboard's unique identifier. Useful for ensuring consistent
  # URLs across Grafana rebuilds and for referencing dashboards in links.
  setUid = uid: dashboard: dashboard // { inherit uid; };

  # Sets the dashboard title displayed in the Grafana UI.
  setTitle = title: dashboard: dashboard // { inherit title; };
}
