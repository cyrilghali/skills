# Loaded with `elixir -r cover_filter.exs -S mix coveralls.json ...`. Makes ExCoveralls instrument only the modules
# named in CRAP_CHECK_COVER_MODULES (comma separated) instead of the whole app. A suite that copies many modules
# with Mimic cannot reset thousands of instrumented modules inside Mimic's 60 s call timeout.
file = Path.join(System.get_env("MIX_DEPS_PATH", "deps"), "excoveralls/lib/excoveralls/cover.ex")
needle = "|> :cover.compile_beam_directory()"
src = File.read!(file)

unless String.contains?(src, needle) do
  IO.puts(:stderr, "cover_filter: #{file} has no #{needle}; ExCoveralls changed, update the script")
  System.halt(4)
end

defmodule CrapCheck.Cover do
  def compile_beams(dir) do
    for name <- String.split(System.get_env("CRAP_CHECK_COVER_MODULES", ""), ",", trim: true),
        beam <- Path.wildcard(Path.join(to_string(dir), "Elixir.#{name}.beam")) do
      :cover.compile_beam(String.to_charlist(beam))
    end
  end
end

Code.compiler_options(ignore_module_conflict: true)
Code.compile_string(String.replace(src, needle, "|> CrapCheck.Cover.compile_beams()"), file)
