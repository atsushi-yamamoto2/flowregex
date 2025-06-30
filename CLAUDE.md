# CLAUDE.md

This file provides guidance to the AI assistant when working with code in this repository.

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

## Development Environment

### Ruby
- **Version**: Assumed to be `3.0.0` or later.
- **Dependencies**: No external gem dependencies. `Bundler` is not used.
- **Testing Framework**: `Minitest` (Ruby's built-in testing library).

### C
- **Compiler**: `gcc` as defined in `c_implementation/Makefile`.
- **Static Analysis**: `cppcheck` is used for static analysis via `make analyze`.

## Development Commands

### Ruby Development
```bash
# Run the main test suite
ruby test/test_flow_regex.rb

# Run a single test method from a file (useful for focused development)
# Example: ruby test/test_flow_regex.rb -n /test_a_specific_pattern/
ruby test/test_flow_regex.rb -n /<test_name_pattern>/

# Use the scratchpad for quick, disposable experiments
ruby quick_test.rb

# Run examples
ruby examples/basic_usage.rb

# Run complex pattern tests
ruby test_complex.rb
```

### C Implementation
```bash
cd c_implementation

# Build all targets
make all

# Run the main test runner
make test
./test_runner

# Run the comprehensive test suite script
./run_all_tests.sh

# Run performance benchmarks
make analysis_benchmark
./analysis_benchmark

# Run static analysis
make analyze

# Run memory checks with Valgrind
make memcheck

# Clean build artifacts
make clean
```

## AI Assistant Guidelines

### Your Role
Your primary role is to assist in developing, testing, and documenting the FlowRegex library. You should be proactive in suggesting improvements, writing clean and efficient code, and adhering to the project's conventions.

### File Roles & Modification Strategy
- **Core Logic (High Caution)**: Files in `lib/` and `c_implementation/src/` are critical. Changes must be carefully considered, well-tested, and justified.
- **Testing (High Activity)**: Files in `test/` and `c_implementation/tests/` should be actively modified and extended. When adding features or fixing bugs, always add or update corresponding tests.
- **Experimentation (Free-form)**: `quick_test.rb` is your scratchpad. Use it freely to try out ideas, demonstrate concepts, or verify logic before integrating it into the main codebase.

### Debugging
The `debug: true` parameter in the Ruby `FlowRegex` constructor is your primary debugging tool. Use it to get detailed execution traces.
```ruby
# Example of enabling debug mode for analysis
FlowRegex.new('a.c', debug: true).match('abc')
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
- **Unit Tests**: Individual component testing in `test/` directory.
- **Integration Tests**: End-to-end pattern matching validation.
- **Performance Tests**: ReDoS immunity and speed comparisons.
- **Fuzzy Matching Tests**: Edit distance algorithm validation.

### C Tests
- **Functional Tests**: Core algorithm correctness via `make test`.
- **Optimization Tests**: MatchMask performance validation.
- **Memory Tests**: Valgrind integration via `make memcheck`.
- **Static Analysis**: `cppcheck` via `make analyze`.

## Development Guidelines

### Code Style
- **Ruby**: Adhere to the standard Ruby community style guide. Prioritize clarity, simplicity, and maintainability.
- **C**: Follow the conventions present in the existing C code (e.g., variable naming, comment style).

### Key Files to Understand
- `lib/flow_regex/parser.rb` - Pattern parsing and AST construction
- `lib/flow_regex/matcher.rb` - Core matching algorithm
- `lib/flow_regex/bit_mask.rb` - Fundamental bitmask operations
- `c_implementation/src/flowregex.c` - C algorithm implementation
- `c_implementation/src/optimized_text.c` - MatchMask optimization

## Pull Request Guidelines

### IMPORTANT: Always Create Pull Requests for Completed Tasks

When you complete any development task, you MUST create a Pull Request using the following process:

1. **Commit your changes** with a descriptive message.
2. **Create a new branch** for the feature/fix.
3. **Ask for user approval** before creating the Pull Request.
4. **Create a Pull Request** using the `gh pr create` command only after user confirmation.

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
🤖 Generated with [Claude Code](https://claude.ai/code) & [Gemini Code Assist]

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Gemini <noreply@google.com>
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
