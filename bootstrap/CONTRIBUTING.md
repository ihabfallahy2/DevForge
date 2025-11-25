# Contributing to Universal Project Bootstrapper

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, version)
   - Relevant logs

### Suggesting Features

1. Check existing feature requests
2. Create a new issue describing:
   - Use case
   - Proposed solution
   - Alternative approaches considered

### Code Contributions

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/my-feature`
3. **Make your changes**
4. **Test your changes**: Run `./tests/run_all_tests.sh`
5. **Commit**: Use clear, descriptive messages
6. **Push**: `git push origin feature/my-feature`
7. **Create Pull Request**

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/bootstrap.git
cd bootstrap

# Run tests
./tests/run_all_tests.sh

# Test locally
./bootstrap.sh --help
```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` shebang
- Include `set -euo pipefail`
- Use meaningful variable names
- Comment complex logic
- Follow existing formatting

### Documentation

- Use Markdown
- Include code examples
- Keep explanations clear and concise
- Update relevant docs when changing code

## Adding New Project Types

To add support for a new project type:

1. **Create template** in `templates/your-type/`
2. **Update detection** in `lib/detect.sh`
3. **Add dependencies** in `lib/install.sh` if needed
4. **Document** in README and docs
5. **Add tests**

## Testing

All contributions should include tests:

```bash
# Unit tests
./tests/unit/test_yourfeature.sh

# Integration tests
./tests/integration/test_yourfeature.sh
```

## Pull Request Process

1. Update documentation for any changed functionality
2. Add tests for new features
3. Ensure all tests pass
4. Update CHANGELOG.md (if exists)
5. Request review from maintainers

## Code Review

Reviewers will check:
- Code quality and style
- Test coverage
- Documentation
- Security implications
- Performance impact

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
