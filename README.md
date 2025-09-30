# Snyk Agentic Integration Wrappers

This repository provides integration wrappers that enable AI coding assistants to leverage Snyk's security platform capabilities through the Model Context Protocol (MCP).

## Overview

The wrappers in this repository allow agentic AI systems (AI coding assistants) to perform security scanning on code, dependencies, infrastructure, and containers using Snyk's comprehensive security platform. This enables AI assistants to proactively identify and fix security vulnerabilities during code generation and review.

## Supported Integrations

### Claude Desktop Extension (DXT)
- **File**: `manifest.json`
- **Purpose**: Packages Snyk as a Claude Desktop Extension
- **Build Script**: `build-dxt.sh` - Creates a `.dxt` file for distribution
- **Capabilities**: Full Snyk security scanning suite via MCP

### Google Gemini Extension
- **File**: `gemini-extension.json`
- **Purpose**: Enables Snyk security scanning in Google Gemini Code Assist
- **Configuration**: Custom context file support and selective tool exposure

### Anthropic MCP Marketplace
- **File**: `server.json`
- **Purpose**: Standard MCP server configuration for any MCP-compatible AI assistant
- **Registry**: Published to the [Model Context Protocol Registry](https://modelcontextprotocol.io) (domain: `snyk.io`)
- **Distribution**: Automated via GitHub Actions workflow on each Snyk CLI release

## Security Capabilities

Through these integrations, AI assistants gain access to:

- **SAST (Static Application Security Testing)**: Code vulnerability scanning
- **SCA (Software Composition Analysis)**: Open source dependency vulnerability detection
- **IaC (Infrastructure as Code)**: Security misconfiguration detection in cloud infrastructure
- **Container Security**: Container image vulnerability scanning
- **AI-specific features**: SBOM generation and testing, AI Bill of Materials (AIBOM)

## How It Works

All integrations use the Snyk CLI's MCP server capability (`snyk mcp -t stdio`), which exposes Snyk's security tools through the Model Context Protocol. The AI assistant can invoke Snyk scans during code generation, review, and security analysis workflows.

## Release Process

The repository uses an automated GitHub Actions workflow (`build-and-release.yml`) that:

1. Triggers on Snyk CLI releases (via `repository_dispatch` or manual `workflow_dispatch`)
2. Builds the Claude Desktop Extension (`.dxt` file) using `build-dxt.sh`
3. Creates a GitHub release with the built artifacts and SHA256 checksums
4. Publishes the updated MCP server configuration to the Anthropic MCP Registry

**This repository is closed to public contributions.**
