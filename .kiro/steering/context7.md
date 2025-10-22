---
inclusion: always
---

# Context7 MCP Integration - MANDATORY

## Critical Rule: ALWAYS Use Context7 Before Writing Code

**MANDATORY**: Before writing ANY code that interacts with libraries, APIs, or CLI tools, you MUST consult Context7 MCP for accurate, up-to-date documentation.

### Why This Matters

- **No Assumptions**: Never rely on pre-trained knowledge about libraries or APIs
- **No Hallucination**: Do not guess or assume API signatures, parameters, or behavior
- **No Alternative Sources**: Context7 is the authoritative source - do not search elsewhere
- **Always Current**: Context7 provides the latest documentation for the actual versions in use

## Workflow for Code Development

### 1. Identify the Library/Tool

Before writing code, identify what external dependencies you need:

- Confluent CLI commands
- Bash built-ins or external tools (jq, curl, etc.)
- Any library or API being called

### 2. Resolve Library ID

Use Context7 to resolve the library name to its proper ID:

```
Use: mcp_Context7_resolve_library_id
Parameter: libraryName (e.g., "confluent-cli", "jq", "bash")
```

### 3. Fetch Documentation

Once you have the library ID, fetch the relevant documentation:

```
Use: mcp_Context7_get_library_docs
Parameters:
  - context7CompatibleLibraryID: from resolve step
  - topic: specific area you need (e.g., "api-key commands", "json parsing")
  - tokens: amount of documentation to retrieve (default: 5000)
```

### 4. Write Code Based on Documentation

Only after consulting Context7 should you write code. Base your implementation on:
- Exact command syntax from documentation
- Correct parameter names and types
- Proper error handling patterns
- Actual return values and output formats

## Examples

### Example 1: Working with Confluent CLI

**WRONG** ❌:

```bash
# Writing code based on assumptions
confluent api-key list --format json
```

**RIGHT** ✅:

```bash
# 1. First resolve library ID
mcp_Context7_resolve_library_id("confluent-cli")

# 2. Get documentation for api-key commands
mcp_Context7_get_library_docs(
  context7CompatibleLibraryID: "/confluent/cli",
  topic: "api-key list command"
)

# 3. Write code based on actual documentation
confluent api-key list -o json  # Correct flag from docs
```

### Example 2: Working with jq

**WRONG** ❌:
```bash
# Assuming jq syntax
echo "$json" | jq '.items[].name'
```

**RIGHT** ✅:
```bash
# 1. Resolve jq library
mcp_Context7_resolve_library_id("jq")

# 2. Get documentation for array filtering
mcp_Context7_get_library_docs(
  context7CompatibleLibraryID: "/stedolan/jq",
  topic: "array iteration and filtering"
)

# 3. Use correct syntax from documentation
echo "$json" | jq -r '.[] | .name'  # Based on actual docs
```

## When to Consult Context7

### ALWAYS Consult for:

- ✅ CLI command syntax and flags
- ✅ API endpoints and parameters
- ✅ Library function signatures
- ✅ Configuration file formats
- ✅ Output formats and parsing
- ✅ Error codes and handling
- ✅ Authentication methods
- ✅ Environment variables

### May Skip for:

- Basic Bash syntax (if, for, while, etc.)
- Standard POSIX utilities with well-known behavior
- Project-specific functions already defined in lib/

## Integration with This Project

### Confluent CLI Commands

Before implementing any `confluent` command:

1. Resolve: `mcp_Context7_resolve_library_id("confluent-cli")`
2. Get docs for specific command area
3. Verify exact syntax, flags, and output format
4. Implement based on documentation

### JSON Processing with jq

Before writing jq filters:

1. Resolve: `mcp_Context7_resolve_library_id("jq")`
2. Get docs for the specific operation needed
3. Use exact syntax from documentation

### External Tools

For any external tool (curl, yq, bc, etc.):

1. Resolve the library ID
2. Fetch relevant documentation
3. Implement based on actual behavior

## Error Prevention

Common mistakes to avoid:

- ❌ Assuming flag names (--format vs -o vs --output)
- ❌ Guessing JSON structure of CLI output
- ❌ Assuming default behaviors
- ❌ Using deprecated commands or flags
- ❌ Incorrect parameter order or types

## Verification Checklist

Before committing code, verify:

- [ ] Consulted Context7 for all external dependencies
- [ ] Used exact command syntax from documentation
- [ ] Verified output format matches documentation
- [ ] Checked error handling based on documented behavior
- [ ] Confirmed all flags and parameters are correct

## Remember

**Your pre-trained knowledge may be outdated or incorrect. Context7 provides the truth. Always consult it first.**
