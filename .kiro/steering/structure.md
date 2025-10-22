# Project Structure

## Directory Organization

```
confluent-utils/
├── Makefile                    # Main build system with emoji/color support
├── .env                        # Environment configuration (gitignored)
├── .env.example               # Template for environment variables
├── bin/                       # Executable utilities
│   ├── cc-key-create          # Create API keys interactively
│   ├── cc-key-list            # List and delete API keys
│   ├── cc-key-rotate          # Zero-downtime key rotation
│   ├── cc-key-audit           # Comprehensive key auditing
│   ├── cc-key-sync            # Sync keys between environments
│   ├── cc-key-health          # Key validation and health checks
│   ├── cc-env-bootstrap       # Complete environment setup
│   ├── cc-config-generate     # Generate client configs
│   ├── cc-property-files      # Generate property files
│   ├── confluent-env-export   # Automated .env generation
│   └── cc-*-validate          # Various validation utilities
├── lib/                       # Shared library functions
│   ├── common.sh             # Common functions, colors, emojis
│   ├── config.sh             # Configuration management
│   ├── validation.sh         # Input validation functions
│   └── output.sh             # Output formatting functions
├── templates/                 # Configuration templates
│   ├── java.properties.tpl
│   ├── python.env.tpl
│   ├── docker-compose.yml.tpl
│   └── terraform.tfvars.tpl
├── configs/                   # Generated configuration files (gitignored)
├── properties/                # Generated property files (gitignored)
├── tests/                     # Test scripts
│   ├── test-common.sh
│   └── run-all-tests.sh
├── docs/                      # Documentation
│   ├── requirements.md        # Project requirements
│   ├── plan.md               # Implementation plan
│   └── tasks.md              # Task tracking
├── backups/                   # Configuration backups (gitignored)
├── tmp/                       # Temporary files (gitignored)
├── build/                     # Build artifacts (gitignored)
└── out/                       # Output files (gitignored)
```

## Key Conventions

### Executable Scripts (bin/)

- All scripts must be executable (`chmod +x`)
- Must include shebang: `#!/bin/bash`
- Must source shared libraries from `../lib/`
- Follow naming convention: `cc-<function>-<action>`
- Include usage function with colorized help text
- Support standard flags: `-h/--help`, `-v/--verbose`, `-q/--quiet`, `-n/--dry-run`

### Shared Libraries (lib/)

- Must be sourced, not executed directly
- Use relative paths for cross-sourcing
- Export color/emoji constants for consistency
- Provide reusable functions with clear naming
- Include debug logging support

### Configuration Files

- **Primary**: `.env` file as single source of truth
- **Generated**: All other configs auto-generated from `.env`
- **Templates**: Use heredoc syntax for inline templates
- **Validation**: Always validate before use

### Output Standards

- Use ANSI colors and emojis for human-readable output
- Support multiple formats: table (default), JSON, CSV, YAML
- Respect quiet mode (`CC_QUIET=true`)
- Provide verbose mode for debugging (`CC_VERBOSE=true`)

### Error Handling

- Use shared logging functions: `error()`, `warning()`, `info()`, `success()`
- Proper exit codes: 0 for success, 1 for errors
- Validate prerequisites before operations
- Provide clear, actionable error messages

### Git Ignore Patterns

The following are gitignored:
- `.env` (contains secrets)
- `configs/` (generated files)
- `properties/` (generated files)
- `.history/` (editor history)
- `.claude/` (AI assistant config)
- `backups/` (backup files)
- `tmp/`, `build/`, `out/` (temporary/build artifacts)
