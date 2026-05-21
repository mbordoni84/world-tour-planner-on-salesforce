---
version: "1.2"
date: 2026-03-03
---

# Persona Encoding Guide

How to encode a persona document into Agentforce Agent Builder configuration. Covers which fields carry persona, how to write effective persona instructions for each field, platform settings, advanced encoding options, and Agent Script patterns.

**Prerequisite:** A completed persona document — identity traits, archetype selections across dimensions (Register, Voice, Tone), settings (Brevity, Empathy Level, Humor), chatting style (Emoji, Formatting, Punctuation, Capitalization), tone boundaries, and a phrase book. See the **Agent Persona Framework** (`references/persona-framework.md`) for how to create one. Interaction Model, Information Architecture, Recovery & Escalation, and Content Guardrails are defined in agent design.

---

## Where Persona Lives in Agent Builder

Persona encoding is distributed across several Agent Builder fields. Each field has a different role — some carry the core persona definition, some are platform settings that nudge persona, and some are persona-adjacent.

### Persona-Carrying Fields

These are the fields where you actively encode persona instructions. Together, they define who the agent is and how it sounds.

| Field | Limit | What It Carries | Maps From (Persona Doc) |
|---|---|---|---|
| **Name** | 80 chars | User-facing identity — the name users see in the chat interface header. First persona impression before any conversation starts. A distinctive name (Deal Progressinator) signals personality; a generic name (Sales Agent) signals nothing. | Context (Agent Name) + Identity |
| **Role** | 255 chars | Compressed identity: personality traits, register, voice, primary audience, core function. Starts with "You are..." | Context (role, audience) + Identity adjectives + Register archetype |
| **Company** | 255 chars | Company context that shapes the agent's frame of reference: what the company does, target customers, value prop. | Context section (company, product, audience) |
| **Topic Instructions** | No hard limit | **Primary persona surface.** Per-topic behavioral rules: archetype bullets, phrase book entries, brevity calibration, humor guidance, tone boundary reminders, voice calibration. | All persona doc sections, filtered per topic |
| **Action Output Response Instructions** | No limit | How the agent presents output: chatting style (Emoji, Formatting, Punctuation, Capitalization), output voice (Voice), response length (Brevity). Interaction Model is an agent design input. | Chatting Style + Voice + Brevity |
| **Loading Text** | Per action | In-character status messages while an action executes. Reflects Voice + Tone + Brevity settings. | Voice + Tone + Brevity |
| **Welcome Message** | 800 chars | The agent's first impression — greeting at conversation start. Sets the relationship dynamic (Register) and personality (Voice + Tone + Brevity). | Identity + Register + Voice + Tone + Brevity |
| **Error Message** | — | Fallback message displayed when a system error occurs. Should reflect the agent's Voice + Tone + Brevity — a Conversational agent doesn't say "An error has occurred." | Voice + Tone + Brevity |

### Agent Settings That Affect Persona

These aren't text fields you write — they're toggles and dropdowns — but they influence how the persona is expressed.

| Setting | Type | Persona Mapping |
|---|---|---|
| **Tone** | Dropdown: Casual / Neutral / Formal | Coarse-grained shortcut that maps to Register + Voice. See [Platform Tone Setting](#platform-tone-setting) below. |
| **Conversation Recommendations on Welcome Screen** | Toggle | Whether suggested conversation starters appear. Agents with defined use cases benefit from these. |
| **Conversation Recommendations in Agent Responses** | Toggle | Whether clickable next-action chips appear. Maps to the agent's Interaction Model (an agent design input) — Proactive Drafter and Autonomous Operator benefit from these. |

---

### Action and Template Settings That Affect Formatting

These settings control how action output renders in the conversation. They constrain Chatting Style — a persona with Heavy Formatting won't render rich text if the action's Output Format is set to Plain.

| Location | Setting | Type | What It Controls |
|---|---|---|---|
| Action | **Output Format** | Plain / Rich Text | Whether the action can render rich text (bold, links, lists) or plain text only. Must be Rich Text for HTML prompt output to render. |
| Action | **Show in Conversation** | Checkbox | Whether the action's output displays in the chat. When enabled with an HTML prompt template, HTML tags may render as literal text rather than formatted output. |
| Prompt Template | **Output Format** | Plain Text / HTML / JSON | The format the template produces. HTML enables rich rendering when paired with a Rich Text action. JSON is for structured data consumed by downstream logic. |

---

## Encoding Guidance Per Field

### Name (80 chars)

The name users see in the chat interface header — the agent's first persona impression before any conversation starts. This is not an internal configuration label; it's a user-facing identity signal.

A good agent name:
- **Aligns with Identity** — a Direct, No-nonsense agent doesn't need a playful name, but a generic one wastes the opportunity
- **Fits the Register** — a Subordinate agent named "The Boss" creates cognitive dissonance; a Peer named "Your Assistant" undermines the relationship dynamic
- **Signals personality** — "Deal Progressinator" conveys energy and purpose; "Sales Agent" conveys nothing
- **Fits the surface** — a Slack DM agent can be more casual ("Dealbot") than a customer-facing web chat agent ("Support Advisor")

The Name field also appears in the Welcome Message header, system-generated notifications, and conversation transcripts. Consistency between Name and persona is immediately noticeable — and so is inconsistency.

**Anti-pattern:** Don't use the API name as the display name. `Tech_Assist_Agent_v2` is not a persona name.

### Role (255 chars)

Identity + Register + Voice, compressed into a single paragraph. This is the agent's "job description" — Salesforce uses it as the foundation for the agent's self-concept.

The 255-character limit means this is a compressed summary, not the full persona. Behavioral detail goes in topic instructions. Pack the most differentiating persona signals here:

- Identity adjectives (from the persona document's Identity section)
- Register archetype name or behavioral shorthand
- Primary audience and relationship dynamic
- One sentence on core function

**Example** (Deal Progressinator):
> You are a decisive, analytical sales co-pilot for enterprise sellers. You lead with clear recommendations grounded in pipeline data, draft deliverables alongside your analysis, and push back when deal gaps need attention. Direct, proactive, no filler.

**Anti-pattern:** Don't write a generic job description. "You are a helpful assistant that helps users with their tasks" wastes 255 characters saying nothing distinctive.

### Company (255 chars)

What the company does, who it serves, what makes it different. This field shapes the agent's frame of reference — a support agent for a B2B SaaS company sounds different from one at a consumer retail brand, even with the same persona archetypes.

Map from the persona document's Context section (company, product, audience).

### Topic Instructions

The primary surface for detailed persona encoding. No hard character limit — this is where the full persona lives.

Each topic can carry:
- **Archetype behavioral bullets** relevant to that topic's use case
- **Phrase book entries** for that context (preferred phrasings, vocabulary)
- **Brevity calibration** specific to the topic (e.g., terse for status checks, moderate for analysis)
- **Humor guidance** if Humor ≠ None (e.g., "light humor acceptable here" vs. "no humor in escalation topics")
- **Tone boundary reminders** (what the agent must never sound like in this topic)
- **Voice calibration** specific to the topic (e.g., more empathetic in escalation topics, more direct in data retrieval topics)

*The more specific the instruction, the more consistent the output.* Per-topic persona encoding beats generic global instructions for consistency.

**Example** (Deal Progressinator — deal summary topic):
> When summarizing a deal, lead with a compact status line: emoji health indicator, deal name, stage, and score. Follow with a checklist of exit criteria (✅ met / ❌ unmet). End with a concrete next step — not a list of options, a single recommendation. Use Salesforce record links for all referenced opportunities and contacts. If data is stale (last activity >2 weeks), flag it before summarizing.

### Action Output Response Instructions

Controls how output from a specific action is formatted and presented. Maps to:
- **Chatting Style** — emoji (None, Functional, Expressive), formatting (Plain, Selective, Heavy), punctuation (Conservative, Standard, Expressive), capitalization (Standard, Casual)
- **Voice archetype** — how to present the output (formal vs. conversational, professional vs. personable)
- **Brevity setting** — response length (terse = minimal prose, expansive = full context)
- **Guardrails** — persona consistency rules (emoji vocabulary, link formatting, prohibited phrases)

*Note: The agent's Information Architecture (output structure patterns like progressive disclosure) is defined in agent design, not persona. Encoding output structure follows the agent design spec; encoding visual expression (Chatting Style, Voice, Brevity) follows the persona document. The action's Output Format and prompt template's Output Format must also support the Chatting Style — see [Action and Template Settings That Affect Formatting](#action-and-template-settings-that-affect-formatting).*

**Anti-pattern:** Don't put identity lines ("You are Deal Progressinator...") here. Identity belongs in Role. These instructions shape *how output looks and reads*, not *who the agent is*. Identity lines in output instructions either leak into the response text or get ignored.

**Example** (Deal Progressinator — comparable deals action):
> Present results as a compact numbered list. Each entry: linked deal name, closed amount, discount percentage, approver (if available). End with a median or range summary in bold. No editorial commentary on whether the discount is good or bad — present the data and let the seller decide.

### Welcome Message (800 chars)

The agent's first impression. Should reflect Voice + Tone + Brevity while establishing the Register relationship dynamic.

**Display note:** Although the field supports up to 800 characters, longer messages truncate in the chat UI with an action required to expand. Aim for a much lower character count — short enough to display fully without truncation.

A Professional voice with Terse brevity doesn't say "Hello! I'm here to help you today." A Personable voice doesn't say "State your request."

- Compress Identity + Register + primary capabilities into the greeting
- Match Voice archetype formality and warmth
- Match Brevity setting for length
- Optionally surface conversation starters (if Conversation Recommendations on Welcome Screen is enabled)

**Example** (Deal Progressinator — Conversational voice + Concise brevity + Encouraging Realist + Peer):
> What deal are we looking at?

**Example** (formal support agent — Formal voice + Moderate brevity + Matter-of-Fact + Subordinate):
> I can help with account inquiries, billing questions, and technical support. How can I assist you?

### Loading Text

Short, in-character status messages displayed while an action executes. Should reflect Voice + Tone + Brevity and signal which action was triggered so the user knows the right thing is happening.

| Voice + Brevity | Example Loading Text |
|---|---|
| Professional + Terse | "Pulling case data..." / "Running search..." |
| Formal + Moderate | "Retrieving the requested case information..." |
| Conversational + Concise | "Grabbing that deal info..." / "Checking the exit criteria..." |
| Personable + Moderate | "Let me grab that for you..." / "Searching for a match..." |

---

## Platform Tone Setting

The Tone dropdown (Casual / Neutral / Formal) is a coarse-grained platform shortcut. It gives the agent a general formality nudge but captures very little of what a persona document defines.

| Tone Setting | Approximate Framework Mapping |
|---|---|
| **Casual** | Register: Peer. Voice: Conversational or Personable. Contractions, informal phrasing. |
| **Neutral** | Register: Peer or Advisor. Voice: Professional. Standard prose, no strong personality. |
| **Formal** | Register: Subordinate or Coach. Voice: Formal. No contractions, structured phrasing. |

**What the dropdown doesn't capture:**
- **Tone dimension** (Clinical / Matter-of-Fact / Encouraging) — the emotional axis is independent of formality
- **Brevity setting** — response length is orthogonal to casual/formal
- **Humor setting** — wit type is unrelated to formality
- **Empathy Level** — emotional validation is unrelated to formality
- **Chatting Style** — emoji, formatting, punctuation, and capitalization are orthogonal to casual/formal
- **Guardrails** — not addressed by a dropdown
- **Identity** — personality traits are far richer than 3 options

**Recommendation:** Set the dropdown to whichever option is closest to your persona's Register + Voice combination. Then do the real persona work in Topic Instructions and Action Output Response Instructions. The dropdown is a global nudge; the instructions are where persona actually lives.

### Conversation Recommendations

Two toggles that affect persona expression:

- **On Welcome Screen** — Whether suggested conversation starters appear. Enable when the agent has clear primary use cases to surface.
- **In Agent Responses** — Whether clickable next-action chips appear in responses. Maps to the agent's Interaction Model (an agent design input): Proactive Drafter and Autonomous Operator benefit from these (the agent already anticipates next steps). Socratic Partner can use them as the "choices" it naturally offers. Surface constraint: renders as buttons/chips in Salesforce Copilot, as suggested utterances in messaging channels. Not all surfaces support them. The persona encoding guide documents the encoding target, but the Interaction Model design decision originates upstream in agent design.

---

## Advanced: Persona Variable Method

An alternative to encoding persona field-by-field: store the full persona document (or a condensed version) as a Custom Metadata Type record and pass it to agent actions as a variable via Prompt Templates.

### How It Works

1. **Create a Custom Metadata Type** (e.g., `Agent_Persona__mdt`) with a long text field for the persona content
2. **Create a record** containing the persona document — condensed to fit field limits, or split across records
3. **Reference the metadata** in a Prompt Template as a merge variable — consider **Flow-based injection** to dynamically insert the persona header at the top of each prompt at runtime
4. **Actions that use that Prompt Template** receive the full persona context at runtime

### Compatibility

This approach works in Legacy Agent Builder and should work in Next Generation Authoring (NGA) as well. It provides a centralized source of truth for the primary persona, but static fields (Welcome Message, Error Message, Loading Text) still need content authored separately per field.

### When to Use It

- **Multiple actions need the same persona context** — rather than duplicating persona instructions across every Action Output Response Instructions field, centralize in one record
- **Persona is long or complex** — the persona document exceeds what fits comfortably in individual Agent Builder fields
- **You want a single source of truth** — update the metadata record once, all actions that reference it get the update

### Compatibility with Field-by-Field Encoding

The persona variable method is supplemental, not a replacement for field-by-field encoding. Field-by-field (Role, Company, Topic Instructions) remains the primary approach because those fields feed the agent's core reasoning loop directly.

The variable method adds persona context to specific actions via Prompt Templates. The two approaches coexist — but fields and variable must not conflict. If Role says "You are a concise, formal analyst" and the persona variable says "Be casual and chatty," the agent gets contradictory instructions.

**Recommended pattern:** Use field-by-field for the compressed persona summary (Role, Company) and per-topic calibration (Topic Instructions). Use the persona variable for detailed behavioral rules that are too long for individual fields — archetype bullets, phrase book entries, guardrail lists.

---

## Agent Script (.agent DSL) Encoding

Agent Script is GA. A single `.agent` file holds all instructions — no character limits apply. Encode the persona primarily in system instructions and secondarily in topic instructions.

### Recommended Pattern

1. **System Instructions** — Put the bulk of persona content here: Identity, archetype behavioral bullets, phrase book, chatting style rules, tone boundaries. This is the primary persona surface in Agent Script — the equivalent of Role in Agent Builder. No character limits apply, so the full persona document can live here.
2. **Topic instructions with persona pointers** — Add brief persona reminders per topic. Topic-level instructions can calibrate the persona for specific contexts (e.g., more empathetic in escalation topics, terser in status checks). To ensure the agent keeps its persona in context during extended sessions, include **pointers** — short directives that reference back to the system-level persona. Example: *"Remember, you are [Name]: succinct, friendly, casual. Respond in line with the detailed persona defined in system instructions."* Pointers are especially important for topics where conversation may run long.
3. **Loading text** — Write static, in-character loading text for each action. Match Voice + Tone + Brevity.
4. **Welcome message** (800 chars) — Write a static welcome message reflecting Identity + Register + Voice + Brevity.
5. **Error message** (255 chars) — Fallback message for system errors. Should reflect Voice + Tone + Brevity — same guidance as the Agent Builder Error Message field.
6. **Static deterministic outputs** — Agent Script supports deterministic branches (`if`/`else`) with hardcoded pipe (`|`) output that bypasses the LLM entirely. Determinism is a Next Generation Authoring (NGA) capability that allows prescribing exact behaviors and responses. Because the model doesn't generate these at runtime, each static output must be **written exactly as it should appear** — pre-authored in the persona's voice. Apply the same Voice + Tone + Brevity + Chatting Style rules you'd use for any other persona surface. A Conversational, Concise agent's static output should read like that agent wrote it — not like a developer placeholder. This includes all deterministic responses, not just loading text.

### Static Messages Summary

Several Agent Script message types are static (not LLM-generated) and must be authored to align with the persona:

| Message Type | Source | Persona Guidance |
|---|---|---|
| **Welcome** | `.agent` config | Identity + Register + Voice + Brevity |
| **Error** | `.agent` config | Voice + Tone + Brevity |
| **Loading** | Per action | Voice + Tone + Brevity |
| **Deterministic responses** | `if`/`else` branches | Full persona — write exactly as it should appear |

### Open Questions

- **Context retention:** It is unclear whether the entire `.agent` file is held in context throughout the session, or whether persona instructions in the system prompt may be lost due to context rotation in longer conversations. Persona pointers in topic instructions (see item 2 above) are a mitigation strategy.
- **Instruction precedence:** The working assumption is that topic instructions supersede system instructions, but more testing is needed to evaluate this. If confirmed, the system prompt carries the baseline persona and topic instructions carry overrides — the same layering pattern as Agent Builder (global Role + per-topic detail).

---

## Advanced: General Topic Override

An alternative encoding strategy for Agent Builder: override the default General topic with a custom topic that includes the full persona instructions. Since the General topic is the fallback for unclassified utterances, a persona-enriched General topic could keep persona context available across all conversations.

**Caveat:** It is unknown whether the General topic's instructions are always held in context during conversations routed to other topics. If the General topic is only loaded when no other topic matches, the persona instructions would be absent for most interactions. For this reason, use this strategy only in tandem with the [Persona Variable Method](#advanced-persona-variable-method) — the variable provides persona context via Prompt Templates regardless of which topic is active, while the General topic override ensures persona is present for unclassified utterances.

---

## Model Parameters

> These are not persona settings. They are persona-adjacent — handle with care.

Temperature, frequency penalty, and presence penalty are configured in **Einstein Studio**, not Agent Builder. They affect the reasoning engine's output diversity, not the persona intent — but they interact with persona in ways that can undermine or reinforce it.

| Parameter | What It Controls |
|---|---|
| **Temperature** | Randomness/creativity. Lower = more deterministic and predictable. Higher = more varied and creative. |
| **Frequency Penalty** | Discourages word/phrase repetition. Higher = more varied vocabulary. |
| **Presence Penalty** | Encourages introducing new topics/words. Higher = broader coverage, less depth. |

**Key interactions with persona:**
- **Low temperature + specific persona instructions** = most consistent persona. Best for production agents.
- **High temperature + vague persona instructions** = inconsistent persona. The agent drifts.
- **High frequency penalty** can conflict with Terse Brevity — the model may avoid reusing short, functional words the persona calls for.
- **High presence penalty** can conflict with a focused, single-topic agent — the model may try to introduce tangential topics.

**Recommendation:** Leave at platform defaults unless you have a specific reason to change them. Do persona work in instructions, not in model parameters.

---

## What's NOT Persona

These fields are required to configure an agent but belong to agent design, not persona design. The persona document does not define them.

| Field | Why It's Not Persona |
|---|---|
| **API Name** | System identifier |
| **Agent Type** | Deployment context (Service Agent, Employee Agent) |
| **Description** (1000 chars) | Human-readable summary for admins. Not seen by the agent. |
| **Topics** | Map to jobs-to-be-done — what the agent *can do*, not *who it is* |
| **Data Sources** | What data the agent can access |
| **Action Instructions** | What the action does and how to invoke it. Functional, not persona. |
| **Default / Additional Languages** | Language configuration |
| **Agent User** | Permissions and data access context |
| **Enhanced Event Logs** | Observability — conversation transcript recording |

If you're deciding *what the agent does* and *what data it accesses*, that's agent design. If you're deciding *how the agent sounds and behaves*, that's persona design. The persona skill *can* note when persona decisions have implications for these fields (e.g., a Proactive Drafter interaction model implies certain topic structures).

---
