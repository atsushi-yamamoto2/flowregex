# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

FlowRegex is a revolutionary regular expression library implementing the "Flow Regex Method" - an automaton-free approach to pattern matching based on Brzozowski's derivative theory. The library eliminates traditional automaton construction and provides theoretical immunity against ReDoS attacks while maintaining linear time complexity.

## Key Architecture

### Ruby Implementation (Main)
- **Core Library**: `lib/flow_regex.rb` - Main entry point
- **Core Components**:
  - `BitMask` - Efficient bitmask operations for position tracking
  - `RegexElement` - Base class for transformation functions
  - `Parser` - Converts regex patterns to executable elements
  - `Matcher` - Core matching engine using function composition
  - `FuzzyMatcher` - Fuzzy matching with edit distance support
- **Advanced Features**:
  - `OptimizedText` - MatchMask pre-computation optimization
  - `TrackedBitMask` - Position tracking for lookahead operations
  - `TwoStageMatcher` - Substring extraction support

### C Implementation (Performance Verification)
- **Location**: `c_implementation/`
- **Purpose**: Performance benchmarking and MatchMask optimization proof-of-concept
- **Features**: Limited subset of Ruby functionality, optimized for speed
- **Build System**: Standard Makefile-based build

## Development Commands

### Ruby Development
```bash
# Basic test execution
ruby test/test_flow_regex.rb

# Quick functionality test
ruby quick_test.rb

# Run examples
ruby examples/basic_usage.rb

# Complex pattern testing
ruby test_complex.rb
```

### C Implementation
```bash
cd c_implementation

# Build all targets
make all

# Run basic tests
make test
./test_runner

# Run comprehensive test suite
./run_all_tests.sh

# Run optimization tests
./test_with_optimization

# Run recursive pattern tests
./test_recursive_patterns

# Performance benchmarks
make analysis_benchmark
./analysis_benchmark

# Clean build artifacts
make clean
```

## Core Concepts

### Function Composition Architecture
FlowRegex uses transformation functions that convert position sets (bitmasks) representing potential match states. Each regex element is a function that processes character input and transforms the active position set.

### Key Technical Features
1. **Linear Time Guarantee**: O(n) for any input, preventing ReDoS attacks
2. **Parallel Processing**: Multiple match paths processed simultaneously via bitmask operations
3. **No Backtracking**: Eliminates exponential complexity through position set management
4. **MatchMask Optimization**: Pre-computed character masks for high-performance matching

### Text Length Limitations
- **Ruby Version**: 10,000 characters (MAX_TEXT_LENGTH)
- **C Version**: 100,000 characters (FLOWREGEX_MAX_TEXT_LENGTH)

## Testing Strategy

### Ruby Tests
- **Unit Tests**: Individual component testing in `test/` directory
- **Integration Tests**: End-to-end pattern matching validation
- **Performance Tests**: ReDoS immunity and speed comparisons
- **Fuzzy Matching Tests**: Edit distance algorithm validation

### C Tests
- **Functional Tests**: Core algorithm correctness
- **Optimization Tests**: MatchMask performance validation
- **Memory Tests**: Valgrind integration via `make memcheck`
- **Static Analysis**: cppcheck via `make analyze`

## Performance Characteristics

### Optimal Use Cases
1. **Genomic Analysis**: 4-character alphabets (ATGC) with large datasets
2. **ReDoS-Vulnerable Patterns**: Patterns that cause exponential backtracking
3. **Repeated Processing**: Same text with multiple patterns
4. **Large-Scale Data**: Where linear time guarantee is critical

### Performance Limitations
- Simple patterns may be slower than optimized traditional engines
- POC implementation prioritizes correctness over speed optimization
- Memory usage scales with text length for position tracking

## Development Guidelines

### Code Organization
- Ruby implementation is the reference implementation with full features
- C implementation focuses on core algorithm performance validation
- Test files are distributed across multiple directories for different purposes
- Examples demonstrate practical usage patterns

### Key Files to Understand
- `lib/flow_regex/parser.rb` - Pattern parsing and AST construction
- `lib/flow_regex/matcher.rb` - Core matching algorithm
- `lib/flow_regex/bit_mask.rb` - Fundamental bitmask operations
- `c_implementation/src/flowregex.c` - C algorithm implementation
- `c_implementation/src/optimized_text.c` - MatchMask optimization

### Common Development Patterns
- Use `debug: true` parameter for detailed execution tracing
- Fuzzy matching requires explicit max_distance parameter
- MatchMask optimization applies automatically for supported patterns
- Two-stage matching enables substring extraction when needed

## Pull Request Guidelines

### IMPORTANT: Always Create Pull Requests for Completed Tasks

When you complete any development task, you MUST create a Pull Request using the following process:

1. **Commit your changes** with a descriptive message
2. **Create a new branch** for the feature/fix
3. **Ask for user approval** before creating the Pull Request
4. **Create a Pull Request** using the `gh pr create` command only after user confirmation

**CRITICAL**: NEVER execute `gh pr create` without explicit user approval. ALWAYS ask "Should I create a Pull Request for this task?" and wait for confirmation before proceeding.

### Pull Request Template

Use this template for all Pull Requests:

```markdown
## Summary
<!-- Brief description of what this PR does -->

## Changes Made
<!-- List of specific changes -->
- 
- 
- 

## Testing
<!-- How was this tested? -->
- [ ] Ruby tests pass (`ruby test/test_flow_regex.rb`)
- [ ] C tests pass (`./run_all_tests.sh`)
- [ ] Manual testing completed
- [ ] Performance benchmarks run (if applicable)

## Type of Change
<!-- Check the relevant box -->
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring

## Implementation Details
<!-- Technical details about the implementation -->

## Performance Impact
<!-- Any performance implications -->
- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance degraded (explain why acceptable)

## Related Issues
<!-- Link any related issues -->
Closes #

---
🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Pull Request Creation Process

After completing any task:

1. **Stage and commit changes**:
   ```bash
   git add .
   git commit -m "descriptive message"
   ```

2. **Create feature branch**:
   ```bash
   git checkout -b feature/task-description
   ```

3. **Push branch**:
   ```bash
   git push -u origin feature/task-description
   ```

4. **Create PR using GitHub CLI**:
   ```bash
   gh pr create --title "Task: Description" --body-file pr_template.md
   ```

### PR Review Checklist

Before creating PR, ensure:
- [ ] All tests pass
- [ ] Code follows project conventions
- [ ] Documentation updated if needed
- [ ] Performance impact considered
- [ ] No breaking changes (or properly documented)
- [ ] Commit messages are descriptive