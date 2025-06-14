# ADR-021: Realistic Tension Pacing (Corrects ADR-014)

## Status

Accepted

## Context

The original streaming optimization approach of "no dead time" proved unrealistic and counterproductive. Meaningful downtime is essential for building tension and making action sequences more impactful.

## Decision

Replace "No Dead Time" with "Meaningful Downtime" that builds tension and makes action sequences more impactful.

## Rationale

- **Realistic Military Pacing**: Honor the "5 minutes of terror, months of boredom" nature of real operations
- **Tension Building**: Use downtime to amplify upcoming action sequences
- **Streaming Optimization**: Transform "boring" moments into engaging content
- **Player Agency**: Prevent passive watching with meaningful choices during lulls

## Implementation

### Realistic Military Pacing

- **Preparation Phases**: Planning, equipment checks, intel gathering create anticipation
- **Travel Phases**: Movement to objectives with growing tension but limited action
- **Contact Phases**: Intense bursts of tactical decision-making and combat
- **Aftermath Phases**: Dealing with consequences, regrouping, medical aid

### Streaming-Optimized Downtime

- **Intel Analysis**: Player reviews enemy patterns, discusses tactical options
- **Equipment Decisions**: Choose loadouts, review team member specializations
- **Route Planning**: Player can override AI suggestions with manual path selection
- **Moral Dilemmas**: Conviction choices during calm moments have more weight
- **Environmental Storytelling**: Discover backstory elements that affect decision-making

### Tension Building Mechanics

- **Countdown Timers**: "Infiltration begins in 30 seconds..." creates anticipation
- **Intelligence Updates**: New information changes tactical considerations
- **Equipment Failures**: Gear malfunctions during quiet moments create pressure
- **Communication Intercepts**: Overhear enemy plans that affect player strategy

### Player Agency During Lulls

- **Observation Windows**: Player spots details the AI planner might miss
- **Psychological Choices**: How to keep team morale up during waiting periods
- **Contingency Planning**: "What if X goes wrong?" preparation phases
- **Resource Management**: Allocate limited supplies between team members

## Corrected Streaming Pattern

**Old Pattern**: Constant tactical decisions → No dead time → Viewer fatigue
**New Pattern**: Build Tension (Extended) → Brief Explosion of Action → Consequence Processing (Extended) → New Intelligence → Repeat

## Streaming Engagement During Downtime

- **Commentary Moments**: Natural breaks for streamers to explain context
- **Audience Polls**: "Which route should we take?" during planning phases
- **Theory Crafting**: Discuss potential enemy responses and counter-strategies
- **Character Development**: Learn team member backstories that affect gameplay

## Consequences

### Positive

- More realistic and engaging pacing that matches military operations
- Meaningful player choices during downtime periods
- Better streaming content with natural commentary opportunities
- Tension building makes action sequences more impactful

### Negative

- Longer gameplay sessions required for complete scenarios
- May not appeal to players expecting constant action
- Requires careful balance between tension and boredom
- More complex content design for meaningful downtime

## Correction Impact

This ADR explicitly corrects ADR-014's "No Dead Time" requirement, demonstrating the self-correcting nature of the design process and prioritizing realistic pacing over artificial entertainment patterns.

## Related Decisions

- Corrects ADR-014 (Twitch Streaming Optimization) pacing approach
- Links to ADR-015 (Imperfect Information) for downtime decision-making
- Supports ADR-007 (Conviction Choice Mechanics) with meaningful timing
- Builds on ADR-013 (Opportunity Window Mechanics) for tension timing
- Enables ADR-023 (MVP Timing Implementation) with realistic expectations
