defmodule MixMinimumElixirVersionTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  import Mix.Tasks.MinimumElixirVersion,
    only: [
      version_sorter: 2,
      deps_version_requirements: 2,
      all_versions: 1,
      parse_requirement: 1,
      run_and_report: 3,
      minimum_elixir_version: 2
    ]

  defp fake_data do
    fn -> Enum.random(?0..?z) end
    |> Stream.repeatedly()
    |> Enum.take(:rand.uniform(50))
    |> to_string()
  end

  defp fake_kv do
    {fake_data(), fake_data()}
  end

  defp fake_kvs do
    junk_stream = Stream.repeatedly(&fake_kv/0)
    Enum.take(junk_stream, :rand.uniform(10))
  end

  defp fake_map(map \\ %{}) do
    Enum.into(fake_kvs(), map)
  end

  defp mock_refs(refs) do
    Enum.map(refs, &fake_map/1)
  end

  test "run_and_report/3" do
    all_versions =
      all_versions([
        %{"ref" => "refs/tags/v1.0.0"},
        %{"ref" => "refs/tags/v1.1.0"},
        %{"ref" => "refs/tags/v1.2.0"}
      ])

    deps_paths = %{
      dep1: nil,
      dep2: nil,
      dep3: nil
    }

    requirement_fn = fn
      :dep1, _ -> "~> 1.0"
      :dep2, _ -> "~> 1.1"
      :dep3, _ -> "~> 1.1"
    end

    deps_version_requirements = deps_version_requirements(deps_paths, requirement_fn)

    assert capture_io(fn ->
             run_and_report(nil, all_versions, deps_version_requirements)
           end) =~ "The minimum Elixir version requirement this project can target is `~> 1.1`"

    assert capture_io(fn ->
             run_and_report("~> 1.1", all_versions, deps_version_requirements)
           end) =~ "This project is already targeting the minimum required Elixir version."

    assert capture_io(fn ->
             run_and_report("~> 1.0", all_versions, deps_version_requirements)
           end) =~
             "This project targets `~> 1.0`, but the minimum version it can target is `~> 1.1`."

    assert capture_io(:stderr, fn ->
             run_and_report("~> 1.0", [], %{})
           end) =~ "Couldn't determine the minimum required Elixir version."
  end

  test "version sorter sorts from oldest to newest" do
    versions = ["1.0.0", "2.4.3", "5.6.1", "0.4.99"]
    sorted = versions |> Enum.map(&Version.parse!/1) |> Enum.sort(&version_sorter/2)

    assert Enum.at(sorted, 0) == %Version{major: 0, minor: 4, patch: 99}
    assert Enum.at(sorted, 1) == %Version{major: 1, minor: 0, patch: 0}
    assert Enum.at(sorted, 2) == %Version{major: 2, minor: 4, patch: 3}
    assert Enum.at(sorted, 3) == %Version{major: 5, minor: 6, patch: 1}
  end

  test "it skips and warns about version requirements that can't be used" do
    fake_deps_paths = %{
      foo: nil,
      bar: nil,
      baz: nil
    }

    requirement_fn = fn
      :foo, _ -> "~> 1.13"
      :bar, _ -> nil
      :baz, _ -> "i love cats"
    end

    self = self()

    captured =
      capture_io(:stderr, fn ->
        requirement_map = deps_version_requirements(fake_deps_paths, requirement_fn)
        send(self, {:requirement_map, requirement_map})
      end)

    requirement_map =
      receive do
        {:requirement_map, requirement_map} -> requirement_map
        val -> flunk("Unexpected receive during test: #{inspect(val)}")
      end

    assert captured =~ "Skipping invalid version requirement for dep bar"
    assert captured =~ "Skipping invalid version requirement for dep baz"

    keys = Map.keys(requirement_map)
    refute :bar in keys
    refute :baz in keys
    assert :foo in keys

    assert requirement_map[:foo] == Version.parse_requirement!("~> 1.13")
  end

  test "it collects version information" do
    mock_data =
      mock_refs([
        %{"ref" => "refs/tags/v0.9.1"},
        %{"ref" => "refs/tags/v1.0.0"},
        %{"ref" => "refs/tags/v1.2.0"},
        %{"ref" => "junk"}
      ])

    all_versions = all_versions(mock_data)

    assert Enum.count(all_versions) == 3
    assert Version.parse!("0.9.1") in all_versions
    assert Version.parse!("1.0.0") in all_versions
    assert Version.parse!("1.2.0") in all_versions
  end

  test "it ignores data it can't use" do
    mock_data = [
      %{},
      %{"ref" => nil},
      fake_map()
    ]

    assert all_versions(mock_data) == []
  end

  test "it parses valid requirements, but returns :error for invalid ones" do
    assert parse_requirement("~> 1.5") == {:ok, Version.parse_requirement!("~> 1.5")}
    assert parse_requirement(nil) == :error
    assert parse_requirement("hello world") == :error
    assert parse_requirement(12) == :error
    assert parse_requirement([]) == :error
  end

  test "minimum_elixir_version/2 returns an elixir version" do
    versions =
      all_versions([
        %{"ref" => "refs/tags/v1.1.0"},
        %{"ref" => "refs/tags/v1.2.0"},
        %{"ref" => "refs/tags/v1.3.0"},
        %{"ref" => "refs/tags/v1.3.1"}
      ])

    version_requirement_map = %{
      dep1: Version.parse_requirement!("~> 1.0"),
      dep2: Version.parse_requirement!("~> 1.3"),
      dep3: Version.parse_requirement!("~> 1.2")
    }

    assert minimum_elixir_version(versions, version_requirement_map) == Version.parse!("1.3.0")
  end
end
