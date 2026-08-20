#!/usr/bin/env bash
set -euo pipefail

readonly contract_files=(README.md main.tf variables.tf outputs.tf examples modules)
readonly forbidden='build_mode[[:space:]]*=|container_image_uri|gateway-agent-runtime-target|target_type[[:space:]]*=[[:space:]]*"AGENT"|~>[[:space:]]*2\.0'

if git grep -En "$forbidden" -- "${contract_files[@]}"; then
  echo "Found a removed v1 public-contract token." >&2
  exit 1
fi

while IFS= read -r example; do
  occurrences=$(grep -Fxc "          - ${example}" .github/workflows/ci.yml || true)
  if [[ "$occurrences" -ne 2 ]]; then
    echo "${example} must appear in both CI example matrices." >&2
    exit 1
  fi
done < <(git ls-files 'examples/*/main.tf' | xargs -n1 dirname | sort -u)

if git grep -En 'actions/(checkout|setup-node)@v[1-6]|github/codeql-action/[^@]+@v[1-3]|hashicorp/setup-terraform@v[1-3]' -- .github/workflows; then
  echo "Found a GitHub action generation that does not run on Node.js 24." >&2
  exit 1
fi
