# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initialized project.
- File templates
- Justfile script for generating AWS Lambda function projects
- This CHANGELOG
- Generated Justfile recipe `create-pre-commit-hook` now produces pre-commit hook directly in `.git/hooks/pre-commit`. If such file doesn't exist it will be created.

### Changed

- Instead of printing concise description what is required to modify in `pyproject.toml` the Justfile `new` recipe will modify them directly.

### Removed

- `.pre-commit.jinja` template in favor of `create-pre-commit-hook`.
- Installed check, because of incosistencies.

### Fixed

- Fix script for determining if actual directory is part of `.git` repository.
