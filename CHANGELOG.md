# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.8.0...v1.0.0) (2026-08-20)

### ⚠ BREAKING CHANGES

* align v1 examples and release gates
* make build and IAM features opt-in
* gateway_targets now uses target_configuration; gateway_mcp_targets and the legacy target outputs are removed, and AWS Provider 6.61 is required.
* restore community module DX
* v0 variables, nested modules, build automation, examples, aliases, and compatibility paths are removed.

### 🚀 Features

* add opt-in AgentCore service modules ([8fa0a1e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/8fa0a1ec296a5e2bce8b1a1d1d0828366305dc4b))
* **agentcore:** complete managed service options ([a042d62](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/a042d62ec6fbb3f4fbf9a3b99b21ea0978f65e91))
* **build:** restore opt-in image pipeline ([00f63b2](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/00f63b26dde0e856a94f9ca59f737bc1dddaca96))
* **gateway:** expose governed gateway surface ([bbd6053](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/bbd60535d1900cc3b9ee03e91c1854a364d94914))
* generalize AgentCore gateway targets ([eaf3536](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/eaf3536e4ddacb61ca64e69f1f89302d6b47aa2f))
* rebuild AgentCore module v1 ([92d9643](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/92d9643d6a7a90497fcead06b06a4a64d7369717))
* **runtime:** expose native runtime artifacts ([1b84971](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/1b8497171751bdc4283318570e2a3ad0713b9173))

### 🐛 Bug Fixes

* **ci:** select podman compose provider ([7ec845b](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/7ec845b221dcf9e0d746b4463b68bccffec48b1e))
* **gateway:** align rule contracts with provider ([0a8beea](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/0a8beeab95f83f13050f576126e9a21233c6be27))
* make build and IAM features opt-in ([f59f2d5](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f59f2d5ec5c051206d439b04feb841411c17db25))
* restore community module DX ([0591421](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/0591421c609e2db6fcd8bcbb8501ecf9f885d009))
* restore published module contract ([20dde74](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/20dde743e869b7717a0db321372b966aec43b373))
* verify Terraform and OpenTofu parity ([62b74e7](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/62b74e7b8f07be0ee6ca58fa0988524c0ae825d3))

### 📖 Documentation

* add v1 AWS smoke criteria ([f55ebb2](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f55ebb22657bb0c32dbed9292484468e7f40b087))
* align v1 examples and release gates ([bc6b91e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/bc6b91e15ae1ee3a11b409607515fc84d822a5ee))
* complete the v1 upgrade contract ([8bc6624](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/8bc6624a0a426d28be8cac90b8340390fbdeb2e2))
* **examples:** separate opt-in capabilities ([7b77fa5](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/7b77fa55f7e809f56c6dd01a474d5070fbc19606))

### 🔧 Code Refactoring

* **ci:** use standard module workflow ([395e61c](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/395e61c70600f2b5267f62d5001707c2439e07bc))

## [0.8.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.7.0...v0.8.0) (2026-07-15)

### 🚀 Features

* **runtime:** add IAM extensions and MMDSv2 enforcement ([8385f14](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/8385f140c3daaed91c250ee5771c52ce1b93c877))

### 🐛 Bug Fixes

* **release:** pin and verify changelog generation ([c41013a](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/c41013ad9cd6729def82baa0841363482f405f7c))

## [0.7.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.6.0...v0.7.0) (2026-07-14)

## [0.6.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.5.1...v0.6.0) (2026-07-12)

## [0.5.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.5.0...v0.5.1) (2026-05-29)

### 🐛 Bug Fixes

* **gateway:** plan self runtime target policy ([eba96f1](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/eba96f1cb99ac1a8fe666e043cd5a45e6db8e4bd))

## [0.5.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.6...v0.5.0) (2026-05-15)

### 🚀 Features

* **gateway:** attach module runtime as target ([d52462e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/d52462ebad3cf64e419103155bade5b9f9bf9123))

## [0.4.6](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.5...v0.4.6) (2026-05-14)

### 🐛 Bug Fixes

* **gateway:** include runtime endpoint invoke ARN ([1e0cdf0](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/1e0cdf00e59a9df6a2d4787f6f154689265081f0))

## [0.4.5](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.4...v0.4.5) (2026-05-14)

### 🐛 Bug Fixes

* **gateway:** wait for invoke policy propagation ([fa7fdcc](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/fa7fdcc13103984cd6b156417bfad834cf65227b))

## [0.4.4](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.3...v0.4.4) (2026-05-14)

### 🐛 Bug Fixes

* **gateway:** add MCP target support ([1cf71db](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/1cf71db7562cbcc5941c9633a1e34396b71a387d))

## [0.4.3](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.2...v0.4.3) (2026-03-04)

### 📖 Documentation

* clarify ARM64 requirement for AgentCore ([f66a523](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f66a5232791fe21dd4511d4d906c656147c20318))

## [0.4.2](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.1...v0.4.2) (2026-02-28)

### 📖 Documentation

* update README for runtime refactor — VPC mode, JWT authorizer, lifecycle, protocol, workload_identity_arn ([f1c35b0](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f1c35b079e86fe240a9e2e7391c7120f78f27783))

## [0.4.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.4.0...v0.4.1) (2026-02-27)

### 📖 Documentation

* polish README — fix emoji glitches, clarify BYO note, improve table, add Windows/CI callout ([6e5db49](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/6e5db49e98136a6ccced45397f12b72fb359f34c))

## [0.4.0](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.3.1...v0.4.0) (2026-02-27)

### 🚀 Features

* allow_bedrock_invoke_all, ecr_pull_principals, codebuild_start_build_command; enterprise patterns in README ([f54e2d2](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/f54e2d242a25c430c2d6320822822ecf262a93d8))

## [0.3.1](https://github.com/LuisOsuna117/terraform-aws-agentcore/compare/v0.3.0...v0.3.1) (2026-02-27)

### 📖 Documentation

* improve README with quickstart, emojis, security notes, BYO clarification ([b904f8e](https://github.com/LuisOsuna117/terraform-aws-agentcore/commit/b904f8e30d00253c777e5155d68a4da4d596cf3e))

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
