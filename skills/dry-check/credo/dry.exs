# Credo config for dry-check: only the duplicate-code check runs.
# DRY_CHECK_DIRS (colon-separated, set by scripts/dry-check.sh) names the source dirs.
dirs = "DRY_CHECK_DIRS" |> System.get_env("lib/") |> String.split(":", trim: true)

%{
  configs: [
    %{
      name: "default",
      files: %{
        included: dirs,
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      strict: true,
      color: false,
      checks: %{
        enabled: [{Credo.Check.Design.DuplicatedCode, []}]
      }
    }
  ]
}
