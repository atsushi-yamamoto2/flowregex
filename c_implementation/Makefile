# FlowRegex C Implementation Makefile

CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g
LDFLAGS = 
TARGET = flowregex
SRCDIR = src
TESTDIR = tests
OBJDIR = obj

# Source files
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)

# Test files
TEST_SOURCES = $(wildcard $(TESTDIR)/*.c)
TEST_OBJECTS = $(TEST_SOURCES:$(TESTDIR)/%.c=$(OBJDIR)/%.o)
TEST_TARGET = test_runner

# Benchmark files
BENCHMARK_TARGET = benchmark

# Main targets
all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS)

# Object files
$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(TESTDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I$(SRCDIR) -c $< -o $@

# Create object directory
$(OBJDIR):
	mkdir -p $(OBJDIR)

# Test target
test: $(TEST_TARGET)
	./$(TEST_TARGET)

$(TEST_TARGET): $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(TEST_OBJECTS)
	$(CC) $^ -o $@ $(LDFLAGS)

# Benchmark target
benchmark: $(BENCHMARK_TARGET)
	./$(BENCHMARK_TARGET)

$(BENCHMARK_TARGET): $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(OBJDIR)/benchmark.o
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/benchmark.o: benchmark.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I$(SRCDIR) -c $< -o $@

# Optimized benchmark target
benchmark_optimized: $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(OBJDIR)/benchmark_optimized.o
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/benchmark_optimized.o: benchmark_optimized.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I. -c $< -o $@

# Fair comparison benchmark target
benchmark_fair_comparison: $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(OBJDIR)/benchmark_fair_comparison.o
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/benchmark_fair_comparison.o: benchmark_fair_comparison.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I. -c $< -o $@

# Simple benchmark target
simple_benchmark: $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(OBJDIR)/simple_benchmark.o
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/simple_benchmark.o: simple_benchmark.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I. -c $< -o $@

# Analysis benchmark target
analysis_benchmark: $(filter-out $(OBJDIR)/main.o, $(OBJECTS)) $(OBJDIR)/analysis_benchmark.o
	$(CC) $^ -o $@ $(LDFLAGS)

$(OBJDIR)/analysis_benchmark.o: analysis_benchmark.c | $(OBJDIR)
	$(CC) $(CFLAGS) -I. -c $< -o $@

# Clean
clean:
	rm -rf $(OBJDIR) $(TARGET) $(TEST_TARGET) $(BENCHMARK_TARGET)

# Install (optional)
install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

# Debug build
debug: CFLAGS += -DDEBUG -g3
debug: $(TARGET)

# Release build
release: CFLAGS += -DNDEBUG -O3
release: clean $(TARGET)

# Static analysis
analyze:
	cppcheck --enable=all $(SRCDIR)/*.c

# Memory check
memcheck: $(TEST_TARGET)
	valgrind --leak-check=full --show-leak-kinds=all ./$(TEST_TARGET)

.PHONY: all clean test benchmark install debug release analyze memcheck
