# Changelog

All notable changes to this project will be documented in this file.

## [0.3.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.2.0...v0.3.0) (2026-02-27)

### 🚀 Features

* add modules/memory and modules/gateway, wire into root wrapper, consolidate root to 4 files, update README for v0.3.0 ([2eb8558](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/2eb85584719132f2856a3e12062bfe349696f4dd))

## [0.2.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.7...v0.2.0) (2026-02-27)

### 🚀 Features

* BYO image, trigger toggle, submodule refactor, create_build_pipeline API ([ad848cc](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/ad848ccf6c46d8229d6b36423da69121786e5d96))

## [0.1.7](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.6...v0.1.7) (2026-02-27)

### 🐛 Bug Fixes

* **iam:** split CloudWatch Logs statements to fix log stream permissions ([b16f513](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/b16f5139371d8f4ee2f453da56888894acdd5d16))

## [0.1.6](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.5...v0.1.6) (2026-02-25)

### 🐛 Bug Fixes

* **security:** add S3 AES-256 encryption, suppress ECR mutable-tag finding ([7843dcc](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/7843dcc376f26ab378bda0e5000efe70ecbf7308))

## [0.1.5](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.4...v0.1.5) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** separate Trivy table gate from SARIF upload, fix exit-code-1 on empty SARIF ([a9bf595](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/a9bf5959681d7a4a3030d8570c61c911a07b7ca4))

## [0.1.4](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.3...v0.1.4) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** add Trivy table-format step to surface unsuppressed findings ([024da07](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/024da07baf0d3796438e6af630cd2649c8cc9bc7))
* **ci:** suppress CodeBuild privileged_mode finding (AVD-AWS-0008) ([92fe11c](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/92fe11c76146480534b6f22d89ce996f388a2087))

## [0.1.3](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.2...v0.1.3) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** use TRIVY_SKIP_CHECK_UPDATE env var to suppress policy download ([36a6054](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/36a6054dd6644b379b85d6971341b7ad18765a1c))

## [0.1.2](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.1...v0.1.2) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** suppress noisy Trivy Rego parse errors via skip-check-update ([d489a8e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/d489a8eaf5596e63a2c03f58b2a7716de557f728))

## [0.1.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.1.0...v0.1.1) (2026-02-25)

### 🐛 Bug Fixes

* **ci:** pin Trivy to v0.59.1, add .trivyignore for module-level suppressions ([e8b8029](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/e8b8029e7fff5b2142dba83ceb376142ac0dffa5))
