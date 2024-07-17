# MixMinimumElixirVersion

<!-- MDOC !-->
Mix task to find the minimum Elixir version requirement for a particular project. It traverses every
dependency defined in the project and then finds which Elixir version satisfies all the
requirements.

⚠️ No validation is done to verify that the project is actually compatible with the emitted version
requirement. For example, the output of this script might indicate a version requirement of `~>
1.13` even if you use
[`Kernel.binary_slice/2`](https://hexdocs.pm/elixir/1.14.0/Kernel.html#binary_slice/2), which was
introduced in Elixir 1.14. You still need to test your project in both the target version as well as
all succeeding versions. 

## Usage

Run the task in the same directory as the `mix.exs` file for the project:

    mix minimum_elixir_version

If nothing went wrong, you should see something like

    This project targets `~> 1.16`, but the minimum version it can target is `~> 1.13`.

<!-- MDOC !-->

## Installation

This package can be installed by adding `mix_minimum_elixir_version` to your list of dependencies in
`mix.exs`:


```elixir
def deps do
  [
    {:mix_minimum_elixir_version, "~> 0.1.5"}
  ]
end
```

Unfortunately, it can't be installed as an archive for some reason. 
