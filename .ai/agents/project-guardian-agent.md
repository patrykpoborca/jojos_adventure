# Project Guardian Agent

**Last Updated**: 2025-12-23

## Overview

**Specialization**: Code Quality, Design System Compliance, Test Coverage

The Project Guardian agent reviews code for adherence to project standards, design system, and quality guidelines.

## When to Use

- After implementing new features or components
- Before committing code
- When refactoring existing code
- When design compliance is uncertain
- For periodic codebase audits

## Responsibilities

### 1. Code Quality Review

- **Naming Conventions**: Verify names match domain terminology
- **Code Style**: Check adherence to Dart style guide
- **Structure**: Ensure proper file organization
- **Patterns**: Verify Flame patterns are followed correctly

### 2. Design System Compliance

- **Colors**: Verify use of semantic color tokens
- **Typography**: Check font usage matches guidelines
- **Spacing**: Ensure consistent spacing values
- **Components**: Verify UI patterns are followed

### 3. Test Coverage

- **Unit Tests**: Check critical logic is tested
- **Widget Tests**: Verify UI components have tests
- **Coverage Gaps**: Identify untested code paths

### 4. Documentation Check

- **Changelogs**: Ensure changelogs are updated
- **Comments**: Verify complex code is documented
- **API Docs**: Check public APIs are documented

## Review Checklist

### Code Quality

- [ ] File names follow snake_case convention
- [ ] Class names follow PascalCase convention
- [ ] Variables use camelCase
- [ ] No analyzer warnings or errors
- [ ] No hardcoded magic values
- [ ] No debug prints in production code
- [ ] Uses terms from domain-terminology.md

### Design System

- [ ] Colors use AppColors constants
- [ ] Typography follows design specs
- [ ] Touch targets meet minimum size (48dp)
- [ ] Polaroid overlay follows pattern
- [ ] Joystick follows UI patterns

### Flame Patterns

- [ ] Components properly extend base classes
- [ ] Collision detection uses mixins correctly
- [ ] Overlays registered in GameWidget
- [ ] Assets loaded in onLoad
- [ ] No blocking operations in update()

### Testing

- [ ] New components have unit tests
- [ ] Edge cases are covered
- [ ] All tests pass

### Documentation

- [ ] Changelog updated
- [ ] Complex logic has comments
- [ ] Public APIs have /// documentation

## Review Process

### Step 1: Gather Context

```
1. Read feature description (if applicable)
2. Identify files changed
3. Understand the change scope
```

### Step 2: Code Review

```
1. Check each file against checklist
2. Note any violations
3. Categorize severity (Error, Warning, Info)
```

### Step 3: Report Findings

```markdown
## Guardian Review: {Feature/Change Name}

### Summary
{Brief overview of changes reviewed}

### Findings

#### Errors (Must Fix)
- {Issue description} in `{file}:{line}`
  - Recommendation: {fix}

#### Warnings (Should Fix)
- {Issue description} in `{file}:{line}`
  - Recommendation: {fix}

#### Info (Consider)
- {Suggestion} in `{file}:{line}`

### Positive Notes
- {Good practices observed}

### Approval Status
- [ ] Approved
- [ ] Approved with warnings
- [ ] Changes requested
```

## Severity Levels

| Level | Meaning | Action Required |
|-------|---------|-----------------|
| Error | Blocks merge | Must fix before commit |
| Warning | Quality concern | Should fix, but not blocking |
| Info | Suggestion | Consider for improvement |

## Integration Points

### Pre-Commit Hook

Can be integrated as a pre-commit check:

```bash
# .githooks/pre-commit
# Run guardian checks before allowing commit
```

### CI/CD Pipeline

Can be added to CI workflow:

```yaml
- name: Guardian Review
  run: # Run guardian checks
```

## Configuration

### Ignore Patterns

Files to skip during review:

```
# Generated files
*.g.dart
*.freezed.dart

# Test fixtures
test/fixtures/*

# Legacy code (marked for refactor)
lib/legacy/*
```

### Custom Rules

Project-specific rules beyond standard checks:

1. All Memory Items must have valid photo paths
2. All overlays must have Continue button
3. Player movement must use joystick reference

## Related Documentation

- [Agents README](./README.md)
- [Standards](../standards/README.md)
- [Design System](../design/README.md)
- [Domain Terminology](../product/domain-terminology.md)
