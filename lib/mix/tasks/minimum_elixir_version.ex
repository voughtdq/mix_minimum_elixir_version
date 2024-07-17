defmodule Mix.Tasks.MinimumElixirVersion do
  @moduledoc "README.md" |> File.read!() |> String.split("<!-- MDOC !-->") |> Enum.fetch!(1)
  @external_resource "README.md"
  @shortdoc "Finds the minimum Elixir version for the current project"
  @tags_url "https://api.github.com/repos/elixir-lang/elixir/git/refs/tags"

  use Mix.Task

  @typedoc false
  @type ref_map :: %{required(String.t()) => term}
  @typedoc false
  @type requirement_map :: %{required(atom) => Version.Requirement.t()}
  @typedoc false
  @type deps_paths :: %{required(atom) => Path.t()}
  @typedoc false
  @type version_requirement_fn :: (atom(), Path.t() -> String.t())
  @typedoc false
  @type versions :: [Version.t()]

  @impl Mix.Task
  def run(_args) do
    _ = Application.ensure_all_started(:req)
    project_version = Mix.Project.get().project()[:elixir]
    run_and_report(project_version)
  end

  @doc false
  @spec run_and_report(nil | String.t(), versions, requirement_map) :: :ok
  def run_and_report(
        project_version,
        versions \\ all_versions(),
        deps_version_requirements \\ deps_version_requirements()
      ) do
    case minimum_elixir_version(versions, deps_version_requirements) do
      nil ->
        Mix.shell().error("Couldn't determine the minimum required Elixir version.")

      %Version{} = elixir_version ->
        formatted = format_version_requirement(elixir_version)

        cond do
          project_version == nil ->
            Mix.shell().info(
              "The minimum Elixir version requirement this project can target is " <>
                "`#{formatted}`"
            )

          project_version == formatted ->
            Mix.shell().info(
              "This project is already targeting the minimum required Elixir version."
            )

          true ->
            Mix.shell().info(
              "This project targets `#{project_version}`, but the minimum version it can target " <>
                "is `#{formatted}`."
            )
        end
    end

    :ok
  end

  defp get_github_refs! do
    @tags_url
    |> Req.get!()
    |> then(fn response -> response.body end)
  end

  @doc false
  @spec all_versions(ref_map) :: [Version.t()]
  def all_versions(ref_map \\ get_github_refs!()) do
    ref_map
    |> Enum.reduce([], fn tag, versions ->
      case tag do
        %{"ref" => "refs/tags/v" <> version} ->
          [Version.parse!(version) | versions]

        _ ->
          versions
      end
    end)
    |> Enum.sort(&version_sorter/2)
  end

  defp deps_paths do
    Mix.Project.deps_paths()
  end

  defp version_requirement_fn(dep, path) do
    Mix.Project.in_project(dep, path, fn _ ->
      Mix.Project.config()[:elixir]
    end)
  end

  @doc false
  @spec deps_version_requirements(deps_paths(), version_requirement_fn()) :: requirement_map()
  def deps_version_requirements(
        deps_paths \\ deps_paths(),
        version_requirement_fn \\ &version_requirement_fn/2
      )
      when is_function(version_requirement_fn, 2) do
    Enum.reduce(deps_paths, %{}, fn {dep, path}, acc ->
      requirement_value = version_requirement_fn.(dep, path)

      case parse_requirement(requirement_value) do
        {:ok, version_requirement} ->
          Map.put(acc, dep, version_requirement)

        :error ->
          Mix.shell().error(
            "Skipping invalid version requirement for dep #{dep}: #{inspect(requirement_value)}"
          )

          acc
      end
    end)
  end

  @doc false
  @spec minimum_elixir_version([Version.t()], requirement_map) :: Version.t() | nil
  def minimum_elixir_version(all_versions, deps_version_requirements) do
    Enum.reduce_while(all_versions, nil, fn version, nil ->
      all_match? =
        Enum.all?(deps_version_requirements, fn {_dep, requirement} ->
          Version.match?(version, requirement)
        end)

      if all_match? do
        {:halt, version}
      else
        {:cont, nil}
      end
    end)
  end

  @doc false
  @spec version_sorter(Version.t(), Version.t()) :: boolean()
  def version_sorter(v1, v2) do
    case Version.compare(v1, v2) do
      :lt -> true
      :eq -> true
      :gt -> false
    end
  end

  defp format_version_requirement(version) do
    "~> #{version.major}.#{version.minor}"
  end

  @doc false
  @spec parse_requirement(String.t()) :: {:ok, Version.Requirement.t()} | :error
  def parse_requirement(requirement_string) when is_binary(requirement_string) do
    Version.parse_requirement(requirement_string)
  end

  def parse_requirement(_) do
    :error
  end
end
