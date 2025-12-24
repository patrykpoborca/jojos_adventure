# Quick Start Guide for AI Documentation

## For AI Agents

When starting work on this project:

1. **Read Main Hub**: Start at `.ai/README.md`
2. **Understand Domain**: Read `.ai/product/domain-terminology.md`
3. **Check Standards**: Read `.ai/standards/feature-development.md`
4. **Find Feature Context**: Look in `.ai/features/{feature_name}/`

### First-Time Setup Checklist

- [ ] Read `CLAUDE.md` in project root
- [ ] Read `.ai/product/product-vision.md`
- [ ] Read `.ai/product/domain-terminology.md`
- [ ] Scan `.ai/technical/architecture-overview.md`
- [ ] Review `.ai/design/README.md`

### Before Each Task

1. Check if feature docs exist in `.ai/features/`
2. If not, create feature directory from templates
3. Review related technical documentation
4. Verify understanding of domain terms

## For Developers

### Starting a New Feature

1. Create folder: `.ai/features/{feature_name}/`
2. Create `feature_description.md` from template
3. Create `implementation_todo.md` from template
4. Create `changelog.md` - update with EVERY change

### Template Location

Templates are in `.ai/standards/feature-development.md`

### Before Committing

1. Update feature changelog
2. Run `flutter analyze` - no errors
3. Run `flutter test` - all pass
4. Verify git hooks pass

### Quick Commands

```bash
# Run the game
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test
```

## For Product Managers

### Defining a Feature

1. Create `.ai/features/{feature_name}/feature_description.md`
2. Include user stories, acceptance criteria
3. Define business rules and constraints
4. Check against `.ai/product/domain-terminology.md`

### Key Documents

- Vision: `.ai/product/product-vision.md`
- Terms: `.ai/product/domain-terminology.md`
- Standards: `.ai/standards/feature-development.md`

## Documentation Principles

### DO

- Maintain changelogs religiously
- Use correct domain terminology
- Keep documentation close to code
- Update docs with every change
- Link to related documents

### DON'T

- Invent new domain terms without consensus
- Skip changelog updates
- Duplicate information across files
- Let documentation drift from reality
- Create docs for trivial changes

## Directory Quick Reference

```
.ai/
├── README.md              # Start here - navigation hub
├── QUICK_START.md         # This file
├── product/               # Business context
│   ├── product-vision.md  # Why we're building this
│   └── domain-terminology.md # CRITICAL - naming
├── design/                # Visual guidelines
│   ├── color-system.md    # Color tokens
│   └── ui-patterns.md     # Component patterns
├── technical/             # How to build
│   ├── architecture-overview.md
│   └── flame-patterns.md
├── features/              # Feature specs
│   └── {feature}/         # Per-feature docs
├── standards/             # Rules and templates
│   └── feature-development.md
├── agents/                # AI agent configs
│   └── project-guardian-agent.md
└── legacy/                # Archived docs
```

## Common Tasks

### "I need to add a new feature"

1. Read `.ai/product/domain-terminology.md`
2. Create `.ai/features/{feature_name}/`
3. Use templates from `.ai/standards/feature-development.md`
4. Implement following technical patterns
5. Update changelog with every commit

### "I need to fix a bug"

1. Find relevant feature in `.ai/features/`
2. Check implementation_todo.md for context
3. Fix the bug
4. Update changelog.md

### "I need to understand the codebase"

1. Read `CLAUDE.md` in project root
2. Read `.ai/technical/architecture-overview.md`
3. Read `.ai/technical/flame-patterns.md`
4. Explore code following the patterns

### "I need to review code quality"

1. Read `.ai/agents/project-guardian-agent.md`
2. Follow the review checklist
3. Check against design system
4. Verify domain terminology usage

## Getting Help

- Navigation: `.ai/README.md`
- Standards: `.ai/standards/README.md`
- Technical: `.ai/technical/README.md`
- Design: `.ai/design/README.md`
