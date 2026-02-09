# INSPECTA-Verus-CI-Action

INSPECTA CI action to conduct analysis of Rust implementation code using Verus

## Inputs

### `sourcepath`

Path to top level Makefile (expects path string).

### `environment-variables`

JSON-formatted dictionary of environment variables to pass to the make system.

## Outputs

## `result`

The JSON-formatted summary of analysis results.

## Example usage

uses: actions/INSPECTA-Verus-CI-Action@v1
with:
  sourcepath: 'system/hamr/microkit'
