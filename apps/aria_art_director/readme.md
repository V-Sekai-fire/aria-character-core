### **INTELLIGENT SUGGESTIONS**

SYSTEM LEARNS "TASTE" FROM STOREFRONT TAXONOMY AND LIBRECOMMENDER DEEP INTEREST NETWORK ALGORITHM. CREATES AN INTELLIGENT ART DIRECTOR FOR PROMPTS.

#### **HIGH-LEVEL EXAMPLE: THE USER'S PERSPECTIVE**

1. **USER GOAL.** USER WANTS A CHARACTER CONCEPT. PROVIDES HIGH-LEVEL GOAL: "CREATE A CUTE, FANTASY FOX-GIRL CHARACTER."  
2. **PLANNER TASK.** SYSTEM TRANSLATES GOAL TO PLANNER TASK: (CREATE-CHARACTER THEME: FANTASY, ARCHETYPE: FOX-PERSON, AESTHETIC: CUTE).  
3. **PLANNER'S LEARNED TASTE.** PLANNER IS PRE-TRAINED. ITS DSL RULEBOOK CONTAINS LEARNED ASSOCIATIONS FOR CREATING HIGH-QUALITY PROMPTS.  
4. **THE PLAN.** PLANNER DECOMPOSES TASK. GENERATES COMPLETE JSON OBJECT. ALL PARAMETERS CHOSEN FOR COHERENCE.  
5. **GENERATION.** JSON FEEDS INTO PIPELINE. A DETAILED, HIGH-QUALITY TEXT PROMPT IS CREATED.  
6. **RESULT.** USER GETS A PROFESSIONAL-GRADE TEXT PROMPT. NO MANUAL SLIDER ADJUSTMENT. AI ACTED AS PROMPT ENGINEER.

#### **LOW-LEVEL EXAMPLE: THE PLANNER'S KNOWLEDGE ENCODING**

1. **THE PUZZLE.** PLANNER MUST CHOOSE FOOTWEAR FOR A PROMPT. THEME IS TRADITIONAL\_SHRINE\_MAIDEN.  
2. **UNTRAINED RULE.** INITIALLY, DSL RULE IS NAIVE. EQUAL CHANCE TO PICK ANY FOOTWEAR.  
3. **TRAINING LOOP.**  
   * **ATTEMPT 1:** PLANNER CHOOSES COMBAT\_BOOTS. THIS CREATES A PROMPT LIKE "...shrine maiden...wearing combat boots...".  
   * **CRITIQUE 1:** ART RULER (LLM-AS-JUDGE) EVALUATES THE PROMPT. JUDGES IT AS INCOHERENT. GIVES LOW REWARD (0.1).  
   * **LESSON 1:** RL PENALIZES THIS CHOICE FOR THIS THEME.  
   * **ATTEMPT 2:** PLANNER CHOOSES FANTASY\_TRADITIONAL. PROMPT IS "...shrine maiden...wearing traditional geta sandals...".  
   * **CRITIQUE 2:** ART RULER JUDGES PROMPT AS COHERENT AND HIGH-QUALITY. GIVES HIGH REWARD (0.95).  
   * **LESSON 2:** RL REINFORCES THIS CHOICE.  
4. **TRAINED RULE.** AFTER THOUSANDS OF CYCLES, ART UPDATES THE DSL. KNOWLEDGE IS ENCODED. THE RULE IS NOW WEIGHTED AND INTERPRETABLE.  
   \# METHOD: SELECT\_FOOTWEAR\_FOR\_SHRINE\_MAIDEN  
   \# DECOMPOSES INTO (WITH LEARNED WEIGHTS):  
   \- (0.95) SET\_PARAMETER('footwear\_item', 'FOOTWEAR\_FANTASY\_TRADITIONAL')  
   \- (0.04) SET\_PARAMETER('footwear\_item', 'FOOTWEAR\_CASUAL\_SHOES')  
   \- (0.01) SET\_PARAMETER('footwear\_item', 'FOOTWEAR\_PRACTICAL\_COMBAT\_BOOTS')

   THE PLANNER'S "TASTE" FOR PROMPT CRAFTING IS NOW AN EXPLICIT, READABLE RULE.

### **CITATIONS**

* Elixir Model Context Protocol (MCP) SDK [https://github.com/cloudwalk/hermes-mcp](https://github.com/cloudwalk/hermes-mcp)  
* **ARIA HYBRID PLANNER.** K. S. ERNEST (IFIRE) LEE. 2025\. [https://github.com/V-Sekai-fire/aria-character-core/blob/main/apps/aria\_hybrid\_planner](https://github.com/V-Sekai-fire/aria-character-core/blob/main/apps/aria_hybrid_planner).  
* **AGENT REINFORCEMENT TRAINER (ART).** HILTON ET AL. 2025\. [https://github.com/OpenPipe/ART](https://github.com/OpenPipe/ART).  
* **PARTCRAFTER.** LIN ET AL. 2025\. ARXIV:2506.05573. [https://github.com/V-Sekai-fire/PartCrafter](https://github.com/V-Sekai-fire/PartCrafter)  
* **MONK SKIN TONE SCALE.** MONK, ELLIS. [https://skintone.google/.](https://skintone.google/)  
* **FACIAL ACTION CODING SYSTEM (FACS).** EKMAN, FRIESEN. 1978\.  
* [https://replicate.com/fire/v-sekai.mediapipe-labeler](https://replicate.com/fire/v-sekai.mediapipe-labeler)  
* [https://replicate.com/fire/flux](https://replicate.com/fire/flux)  
* [https://github.com/KhronosGroup/glTF/blob/interactivity/extensions/2.0/Khronos/KHR\_interactivity/Specification.adoc\#introduction-general](https://github.com/KhronosGroup/glTF/blob/interactivity/extensions/2.0/Khronos/KHR_interactivity/Specification.adoc#introduction-general)  
* [github.com/thisoverride/BoothPM-SDK](http://github.com/thisoverride/BoothPM-SDK)
