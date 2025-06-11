# Standard Operating Procedure: Coding Workflow Cycle Time Analysis

**Document ID:** SOP-DEV-001  
**Version:** 1.0  
**Date:** June 11, 2025  
**Author:** AriaEngine Development Team  
**Classification:** Internal Development Process  

## Purpose

This SOP defines the standardized process for analyzing coding workflow cycle times to measure development velocity, identify bottlenecks, and optimize team productivity in the Aria Character Core project.

## Scope

This procedure applies to:
- All development team members working on Aria Character Core
- Git commit analysis and development pattern identification
- Performance measurement and optimization workflows
- Project management and velocity tracking

## Definitions

- **Cycle Time**: The elapsed time between consecutive commits in the development workflow
- **Rapid Cycle**: Development cycles under 1 hour, indicating quick fixes or small changes
- **Moderate Cycle**: Development cycles between 1-5 hours, representing standard feature work
- **Extended Cycle**: Development cycles over 5 hours, indicating major features or complex refactors
- **Development Velocity**: The rate at which development work is completed, measured in cycles per time period

## Tools and Dependencies

### Required Software
- Elixir runtime environment
- Git version control system
- Mix build tool
- Terminal/command line access

### Script Location
- Primary script: `scripts/analyze_commit_cycles.exs`
- Workspace root: `/Users/setup/Developer/aria-character-core`

## Procedure

### 1. Manual Analysis

#### Step 1.1: Navigate to Project Root
```bash
cd /Users/setup/Developer/aria-character-core
```

#### Step 1.2: Run Full Analysis
```bash
elixir scripts/analyze_commit_cycles.exs
```

**Expected Output:**
- Analysis timestamp and commit count
- Statistical measures (average, median, min, max cycle times)
- Development pattern breakdown (rapid/moderate/extended cycles)
- Example commits for each pattern category

#### Step 1.3: Generate Commit Message Format
```bash
elixir scripts/analyze_commit_cycles.exs --format-commit
```

**Expected Output:**
```
📊 Coding Workflow Cycle Times:
• Avg: 102.1m | Med: 28.1m
• Range: 7.6m - 7.7h
• Rapid cycles: 7/9
• Extended cycles: 1/9
```

### 2. Mix Integration

#### Step 2.1: Run Analysis via Mix
```bash
mix cycle.analyze
```

This command executes the full cycle time analysis within the Mix environment.

### 3. Automated Testing

#### Step 3.1: Verify Cycle Time Measurement Tests
```bash
mix test apps/aria_workflow/test/workflow_system_test.exs
```

**Test Coverage Includes:**
- Development cycle time measurement
- Workflow execution timing with spans
- Command execution cycle times
- Development pattern efficiency analysis
- Git workflow cycle measurement integration
- Development velocity tracking over time

## Analysis Interpretation

### Performance Benchmarks

#### Excellent Performance
- Average cycle time: < 60 minutes
- Rapid cycles: > 70% of total
- Extended cycles: < 10% of total

#### Good Performance
- Average cycle time: 60-120 minutes
- Rapid cycles: 50-70% of total
- Extended cycles: 10-20% of total

#### Needs Improvement
- Average cycle time: > 120 minutes
- Rapid cycles: < 50% of total
- Extended cycles: > 20% of total

### Development Patterns

#### Rapid Development (< 1 hour)
**Indicators:**
- Bug fixes
- Minor feature additions
- Test additions
- Documentation updates
- Configuration changes

**Optimization:** Maximize these cycles for quick iteration

#### Moderate Development (1-5 hours)
**Indicators:**
- Feature implementation
- API development
- Integration work
- Performance optimization

**Optimization:** Standard development work, monitor for efficiency

#### Extended Development (> 5 hours)
**Indicators:**
- Major refactoring
- Architecture changes
- Complex feature development
- Research and exploration

**Optimization:** Break down into smaller cycles when possible

## Quality Assurance

### Pre-Commit Checklist
- [ ] Run cycle time analysis
- [ ] Verify development pattern distribution
- [ ] Check for outlier cycle times
- [ ] Include cycle time data in commit message (if significant changes)

### Code Review Considerations
- Review cycle time patterns for code complexity indicators
- Identify opportunities to break down extended cycles
- Validate that rapid cycles maintain code quality

## Troubleshooting

### Common Issues

#### Issue: Script fails with timestamp parsing errors
**Solution:** Verify git log format compatibility
```bash
git log --oneline --pretty=format:"%h %cI %s" -5
```

#### Issue: No cycle time data generated
**Solution:** Ensure sufficient commit history (minimum 2 commits)

#### Issue: Mix command not found
**Solution:** Verify script permissions and file path
```bash
chmod +x scripts/analyze_commit_cycles.exs
ls -la scripts/analyze_commit_cycles.exs
```

### Performance Issues

#### Large Repository Analysis
- Limit analysis to recent commits (`-10`, `-20`, etc.)
- Use `--format-commit` for quick summaries
- Consider caching results for large datasets

## Documentation and Reporting

### Regular Reports
- **Daily:** Include cycle time summary in standup reports
- **Weekly:** Generate development velocity trends
- **Monthly:** Analyze pattern shifts and optimization opportunities

### Commit Message Integration
When committing significant workflow improvements or completing major development cycles, include cycle time data:

```
feat: implement new API endpoint with enhanced error handling

📊 Coding Workflow Cycle Times:
• Avg: 102.1m | Med: 28.1m
• Range: 7.6m - 7.7h
• Rapid cycles: 7/9
• Extended cycles: 1/9
```

## Related Documentation
- `performance-tracing-sop.md`: Performance monitoring and tracing procedures
- `architecture.md`: System architecture and design principles
- `monitoring-decision-document.md`: Monitoring strategy and implementation decisions

## Approval

**Prepared by:** AriaEngine Development Team  
**Reviewed by:** Technical Lead  
**Approved by:** Project Manager  

**Document Control:**
- Next Review Date: September 11, 2025
- Change Control: Version controlled in Git repository
- Distribution: All development team members

---

*This document is part of the Aria Character Core development standards and is subject to revision based on project evolution and team feedback.*
