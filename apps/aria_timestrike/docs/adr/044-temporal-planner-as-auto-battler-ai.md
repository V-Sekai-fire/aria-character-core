# ADR-044: Temporal Planner as Auto Battler/Auto Chess Strategic AI

## Status

Accepted

## Date

2025-06-14

## Context

The AriaEngine temporal planner involves complex concepts like Goal-Task-Network decomposition, multi-agent coordination, and temporal backtracking that can be difficult for developers and stakeholders to understand. However, these concepts are directly analogous to the strategic AI systems found in popular auto battler/auto chess games like Teamfight Tactics, Auto Chess, and Hearthstone Battlegrounds.

By framing our temporal planner in terms familiar to the 18-35 demographic who regularly play these games, we can make the technical architecture more accessible and intuitive for team members, stakeholders, and future developers working on the system.

## Decision

**Frame the temporal planner as an advanced auto battler strategic AI** that handles positioning, timing, ability coordination, and adaptive strategy in real-time tactical scenarios. This analogy provides an intuitive mental model for understanding complex temporal planning concepts.

## Auto Battler/Auto Chess Analogy

### **Core Concept: Strategic AI That Plans Multiple Moves Ahead**

Just like how top-tier auto chess players think several rounds ahead and adapt their strategy based on changing board states, our temporal planner thinks multiple time steps ahead and adapts plans based on changing game conditions.

### **Maya's Scenario = Auto Chess Round**

**Think of Maya's canonical problem (ADR-035) like this:**

- **Maya** = Your carry unit (like a fed Jinx or Kayn)
- **Alex** = Your support unit (like Lulu or Thresh)
- **Soldier2** = Enemy carry that needs to be eliminated
- **The Mission** = A crucial auto chess round where you need perfect positioning and timing to win

### **Goal-Task-Network = Strategic Decomposition**

**Auto Chess Equivalent:**

```
High-level strategy: "Win this round"
↓
Tactical breakdown:
1. Position carries for optimal DPS
2. Use CC abilities at right moment
3. Focus fire priority target
4. Reposition if frontline breaks
```

**Our Temporal Planner:**

```
High-level goal: "eliminate_soldier_patrol"
↓
Task breakdown:
1. Reconnaissance Task (like scouting enemy positioning)
2. Historical Analysis Task (like predicting enemy ability rotations)
3. Coordination Task (like timing your units' abilities together)
4. Opportunity Exploitation Task (like capitalizing on enemy misposition)
```

### **Multi-Agent Coordination = Team Synergy**

**Auto Chess Teams:**

- **Jinx** needs **Lulu** to polymorph threats at the right moment
- **Timing matters**: Lulu's polymorph too early = wasted, too late = Jinx dies
- **Positioning matters**: Units need to be in range to support each other

**Our Temporal Planner:**

- **Maya** needs **Alex** to scout and provide information at the right moment
- **Timing matters**: Alex scouts too early = info becomes stale, too late = Maya can't react
- **Positioning matters**: Agents need to be in position to coordinate effectively

### **Temporal Backtracking = Strategic Adaptation**

This is where our system goes **beyond** normal auto chess AI:

#### **Level 1 Adaptation: Information Gathering** (Like scouting enemy comps)

**Auto Chess:** "I thought they were running Rangers, but they pivoted to Mages - need to build MR"
**Our System:** "I thought Soldier2 was at fixed position, but Alex revealed he's on patrol - need to replan timing"

#### **Level 2 Adaptation: Tactical Adjustment** (Like repositioning mid-fight)

**Auto Chess:** "Enemy assassin jumped my backline - need to reposition carry"
**Our System:** "Soldier2's patrol has waypoint pauses - need to exploit pause windows"

#### **Level 3 Adaptation: Opportunity Exploitation** (Like capitalizing on RNG)

**Auto Chess:** "Enemy got bad positioning from Blitzcrank hook - all-in now!"
**Our System:** "Archer1 blocks line of sight at tick 50 - use concealment for surprise attack"

#### **Level 4 Adaptation: Emergency Pivot** (Like desperate late-game adaptation)

**Auto Chess:** "Original strategy failed - pivot to different win condition before elimination"
**Our System:** "Coordination failed - direct interception before target reaches safety"

### **Real-Time Planning = Micro Management**

**Auto Chess Players Know This:**

- Good players plan positioning 2-3 rounds ahead
- Great players adapt strategy based on what other players are doing
- Pro players make split-second decisions during combat phase

**Our System Does This But For Real-Time Combat:**

- Plans multiple time steps ahead (like auto chess rounds)
- Adapts strategy based on changing game state (like reacting to other players)
- Makes split-second decisions during active gameplay (like combat micro)

### **JSON-LD Solution Network = Game State Representation**

**Auto Chess Analogy:**
Think of how TFT tracks every unit, their items, positioning, abilities, synergies, and how they all interact. The game state is incredibly complex but represented in a structured way.

**Our System:**
JSON-LD with chibifire.com namespace is like TFT's comprehensive game state tracking, but for temporal plans. It tracks:

- Agent positions and abilities (like unit stats)
- Temporal constraints (like ability cooldowns)
- Coordination plans (like synergy requirements)
- Opportunity windows (like positioning advantages)

### **Why This Matters: Performance Under Pressure**

**Auto Chess Reality:**

- You have limited time per round to make decisions
- Information changes constantly (other players' strategies, RNG, economy)
- Small timing/positioning mistakes lose you the game
- Need to balance multiple objectives simultaneously

**Our Temporal Planner:**

- Must plan within 10ms performance constraints (like auto chess time pressure)
- Information changes constantly (enemy movement, opportunity windows)
- Small timing/coordination mistakes fail the mission
- Must balance multiple agent actions simultaneously

## Technical Implementation Through Auto Chess Lens

### **STN Solver = Ability Timing Engine**

**Auto Chess:** "If Jinx ults at 2.5 seconds, and Lulu polymorphs at 3.0 seconds, does the combo work?"
**Our System:** "If Maya moves at tick 10, and Alex scouts at tick 15, do the timings align for coordination?"

### **Timeline Data Structure = Unit Behavior Tracking**

**Auto Chess:** "Track when each unit will use abilities, move, target switch"
**Our System:** "Track when each agent will move, scout, attack, coordinate"

### **Resource Constraints = Mana/Cooldown Management**

**Auto Chess:** "Lulu needs 50 mana to polymorph, gets 10 mana per second"
**Our System:** "Maya needs line of sight to cast, Alex needs movement range to scout"

### **Backtracking Engine = Strategic Pivot System**

**Auto Chess:** "This positioning isn't working - try different formation"
**Our System:** "This timing isn't working - try different coordination sequence"

## Stakeholder Communication Benefits

### **For Product Managers:**

"It's like building the strategic AI that auto chess pros use, but for real-time tactical games."

### **For Engineers:**

"We're implementing the decision-making engine that thinks multiple moves ahead, like auto chess AI but with temporal constraints."

### **For Designers:**

"Think of how auto chess players coordinate unit positioning and ability timing - we're automating that level of strategic thinking."

### **For QA:**

"Testing is like verifying that our AI can win consistently against different auto chess compositions and RNG scenarios."

## Performance Expectations Through Gaming Lens

### **Auto Chess Performance Standards:**

- **Response Time:** Players expect near-instant feedback when positioning units
- **Decision Quality:** AI should make plays that human experts would consider "good"
- **Adaptation Speed:** Must quickly adapt when strategy isn't working
- **Consistency:** Should win consistently against weaker strategies

### **Our Temporal Planner Standards:**

- **Response Time:** ≤10ms planning (faster than auto chess visual updates)
- **Decision Quality:** Plans should succeed against canonical problems consistently
- **Adaptation Speed:** Must replan faster than initial planning
- **Consistency:** Should solve Maya's scenario >95% of the time

## Common Auto Chess Problems We Solve

### **"I Know What I Want But Can't Execute"**

**Auto Chess:** "I want to run 6 Mages but can't get the positioning/timing right"
**Our Solution:** Goal decomposition breaks "eliminate patrol" into executable micro-tasks

### **"Everything Depends on Everything Else"**

**Auto Chess:** "Jinx positioning depends on Lulu placement depends on enemy threats depends on..."
**Our Solution:** STN solver handles interdependent timing constraints automatically

### **"I Need to Adapt Mid-Fight"**

**Auto Chess:** "Enemy assassin jumped my carry - need to immediately reposition everything"
**Our Solution:** Temporal backtracking replans when original strategy hits conflicts

### **"Timing Windows Are Everything"**

**Auto Chess:** "Enemy Zephyr wears off in 2 seconds - need to position for that exact moment"
**Our Solution:** Opportunity window detection exploits precise timing advantages

## Consequences

### **Positive**

- **Accessible Mental Model:** Complex temporal planning concepts become intuitive
- **Stakeholder Buy-in:** Non-technical stakeholders understand the value proposition
- **Team Communication:** Shared vocabulary for discussing temporal planning features
- **Quality Benchmarks:** Auto chess performance standards provide clear targets

### **Negative**

- **Analogy Limitations:** Some temporal planning concepts don't map perfectly to auto chess
- **Audience Assumptions:** Requires familiarity with auto battler/auto chess games
- **Complexity Understated:** Auto chess analogy might make the technical challenge seem simpler than it is

## Cross-References

- **ADR-035**: Canonical temporal backtracking problem (the "auto chess round" we must win)
- **ADR-042**: Cold boot implementation order (building the "strategic AI engine")
- **ADR-043**: Total order to partial order transformation (optimizing "ability rotations")
- **ADR-040**: STN solver selection (the "timing calculation engine")
- **ADR-041**: Tech stack requirements (the "game engine" that powers the AI)

## Validation Through Gaming Metrics

The temporal planner succeeds when it demonstrates auto chess-level strategic thinking:

- **Multi-step Planning:** Plans 3+ moves ahead consistently
- **Adaptation Speed:** Pivots strategy faster than human reaction time
- **Coordination Precision:** Manages multiple units with frame-perfect timing
- **Pressure Performance:** Maintains decision quality under time constraints
- **Learning Efficiency:** Improves strategy through experience like skilled players

This auto battler/auto chess framework provides an intuitive way to communicate the sophisticated AI capabilities we're building while maintaining technical precision in implementation.
