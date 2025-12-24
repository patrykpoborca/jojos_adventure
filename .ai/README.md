# AI Documentation Hub - Memory Lane

**Last Updated**: 2025-12-23

This directory contains comprehensive AI agent documentation for the "Memory Lane" game project - a sentimental 2D top-down exploration game celebrating a baby's first year of life.

## Directory Structure

```
.ai/
├── README.md              # This file - main navigation hub
├── QUICK_START.md         # Quick start guide for AI agents and developers
├── product/               # Product strategy and business context
│   ├── README.md          # Product documentation navigation
│   ├── product-vision.md  # Product vision and strategy
│   └── domain-terminology.md # Critical domain terms
├── design/                # Design system and UX patterns
│   ├── README.md          # Design documentation navigation
│   ├── color-system.md    # Color palette and tokens
│   └── ui-patterns.md     # UI component patterns
├── technical/             # Technical architecture and implementation
│   ├── README.md          # Technical documentation navigation
│   ├── architecture-overview.md # System architecture
│   └── flame-patterns.md  # Flame engine patterns
├── features/              # Feature specifications and tracking
│   └── example_feature/   # Example feature structure
│       ├── feature_description.md
│       ├── implementation_todo.md
│       └── changelog.md
├── standards/             # Development standards and templates
│   ├── README.md          # Standards navigation
│   └── feature-development.md # Feature development workflow
├── agents/                # AI agent configurations
│   ├── README.md          # Agents overview
│   └── project-guardian-agent.md # Code quality agent
└── legacy/                # Archived documentation
```

## Quick Navigation

### By Role

- **Product Managers**: Start at [product/README.md](./product/README.md)
- **Designers**: Start at [design/README.md](./design/README.md)
- **Developers**: Start at [technical/README.md](./technical/README.md)
- **AI Agents**: Start at [agents/README.md](./agents/README.md)

### By Task

- **Implementing a Feature**: See [standards/feature-development.md](./standards/feature-development.md)
- **Reviewing Code**: See [agents/project-guardian-agent.md](./agents/project-guardian-agent.md)
- **Design System**: See [design/README.md](./design/README.md)
- **Understanding the Game**: See [product/product-vision.md](./product/product-vision.md)
- **Technical Architecture**: See [technical/architecture-overview.md](./technical/architecture-overview.md)
- **Domain Terminology**: See [product/domain-terminology.md](./product/domain-terminology.md) (CRITICAL)

### Quick Links

| Document | Purpose |
|----------|---------|
| [Product Vision](./product/product-vision.md) | Why we're building this |
| [Domain Terms](./product/domain-terminology.md) | Consistent terminology |
| [Architecture](./technical/architecture-overview.md) | How the system works |
| [Feature Standards](./standards/feature-development.md) | How to implement features |

## Project Context

**Memory Lane** is a Christmas gift game for the developer's wife, celebrating their baby's first year. Key aspects:

- **Genre**: 2D top-down exploration
- **Engine**: Flutter + Flame Engine
- **Core Mechanic**: Baby crawls through house, touching items reveals photo memories
- **Goal**: Reach Christmas tree for final montage

## Before Starting Any Work

1. Read [product/domain-terminology.md](./product/domain-terminology.md) - ensures consistent naming
2. Review [technical/architecture-overview.md](./technical/architecture-overview.md) - understand the codebase
3. Check [features/](./features/) for existing feature specs
4. Follow [standards/feature-development.md](./standards/feature-development.md) workflow

## Maintenance

- Update documentation with every significant change
- Create changelogs for all features
- Archive outdated docs to `legacy/`
- Keep terminology consistent across all docs
