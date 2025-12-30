# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Repository status

As of this WARP.md creation, the repository does not contain any detectable source files, build manifests, or documentation (for example, no `README.md`, `package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Makefile`, or solution/project files were found).

Future agents should re-scan the repository when new files are added and update this document to reflect the actual project layout and workflows.

## Commands: build, test, lint, and development

There are currently no project-specific build, test, or lint commands discoverable from the repository contents.

When tooling is introduced, future agents should:

- Infer the primary language and toolchain from newly added files (for example: `package.json` for Node, `pyproject.toml` for Python, `go.mod` for Go, `.sln`/`.csproj` for .NET, etc.).
- Document in this section how to:
  - Build or run the project
  - Run the full test suite
  - Run a single test (include concrete command examples)
  - Run any linters or formatters

Keep this section focused on concrete commands actually used in this repo (for example, `npm test -- --watch`, `pytest path/to/test_file.py::TestClass::test_case`, `go test ./...`, `dotnet test`, etc.). Avoid adding generic guidance that is not backed by real tooling in the repo.

## Architecture and structure

Because there is no source code in the repository yet, there is no project-specific architecture to document.

When code is added, future agents should expand this section with a high-level overview that captures the big-picture structure, such as:

- Primary entrypoints (CLI, web server, library modules, etc.)
- Major modules/packages and how they interact
- Any key architectural patterns (for example, layered architecture, hexagonal ports/adapters, CQRS, etc.)
- How data flows through the system (for example, request handling, persistence, background jobs)

Focus on cross-cutting structure that requires looking across multiple files or directories, rather than enumerating every individual file.
