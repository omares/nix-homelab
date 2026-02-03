---
name: serena
description: Powerful coding agent toolkit capable of turning an LLM into a fully-featured agent that works directly on your codebase
license: MIT
compatibility: opencode
metadata:
  audience: developers
  workflow: coding
---

## What I do

- Analyze and understand complex codebases across multiple files
- Find symbols (classes, functions, methods) by name or pattern
- Search for code patterns and references across the entire codebase
- Perform safe, semantic code edits (rename symbols, replace implementations)
- Insert new code before or after existing symbols
- Explore project structure and file relationships
- Maintain code consistency when making changes

## When to use me

Use me when you need to:
- **Understand complex code**: Before making changes to unfamiliar code
- **Refactor code**: Rename symbols, extract methods, or restructure code
- **Implement new features**: That interact with existing code
- **Find code patterns**: Search for specific implementations or usages
- **Make multi-file changes**: That require understanding relationships between components

## Workflow

### For Code Analysis
1. Call `serena_initial_instructions` first to understand my capabilities
2. Check if onboarding was performed with `serena_check_onboarding_performed`
3. Explore the codebase using:
   - `serena_list_dir` to understand project structure
   - `serena_search_for_pattern` to find specific code patterns
   - `serena_find_symbol` to locate specific classes, functions, or methods

### For Making Changes
1. First, find the symbol you want to modify using `serena_find_symbol`
2. Then make the change using one of:
   - `serena_replace_symbol_body` - Replace a function/class implementation
   - `serena_insert_before_symbol` - Add code before a symbol
   - `serena_insert_after_symbol` - Add code after a symbol
   - `serena_replace_content` - Pattern-based content replacement

### For Complex Refactoring
1. Research thoroughly using find/search tools
2. Think about collected information with `serena_think_about_collected_information`
3. Verify task adherence with `serena_think_about_task_adherence`
4. Confirm completion with `serena_think_about_whether_you_are_done`

## Best Practices

- Always read the initial instructions first
- Use symbolic operations (find_symbol, replace_symbol_body) instead of regex when working with code entities
- Search before making changes to understand the full context
- Use the thinking tools to validate your approach before and after making changes
- Prefer editing existing files over creating new ones unless required
