# Onboarding questions: what to ask and why

Goal: a short onboarding (5 questions, under a minute) where every answer feeds a decision the app makes, and later becomes a clean feature for a model that personalises the morning (alarm, wake-up tasks, how strictly apps stay locked).

## What's wrong with the current set

| Current question | Problem |
| --- | --- |
| What is your focus? (Low / Medium / High) | Ambiguous: focus on what? Users interpret it differently, so the answer is noise. |
| What distracts you? (Social media / Games / Messages) | Useful, but the app picker later collects the real apps, which is better data. |
| When should you wake up? | Keep. It's the anchor for everything. |
| What are your goals? (Focus / Exercise / Reading) | Too generic, overlaps with "focus" and doesn't map to tasks. |
| How experienced are you? | Experienced at what? Nothing in the app depends on it. |

## Principles (from the research)

1. **Use validated wording where it exists.** Sleep science has short, validated items for chronotype, morning alertness and sleep quality. Borrowing their wording makes the data comparable and meaningful instead of made up.
2. **Ask about behaviour, not self-image.** "When do you first pick up your phone?" predicts behaviour better than "How distracted are you?".
3. **Every question must change something.** If no screen, default or model feature uses the answer, drop it.
4. **Keep onboarding short; ask more later.** Ask the essentials up front, then ask the rest in-app over the first week (one tap after a morning), when the user already trusts the app.
5. **The best training data comes after onboarding.** Onboarding answers are the cold start; what actually happens each morning (snoozes, time to get up, tasks done) is what a model learns from. Log it from day one.
6. **Not a medical screen.** Avoid clinical instruments (insomnia or depression scales) in onboarding. They need care to interpret and can make the product read like a diagnosis.

## Recommended questions

The "Feeds" column says what each answer is used for.

| # | Question (UI copy) | Type | Options / format | Feeds | Source |
| --- | --- | --- | --- | --- | --- |
| 1 | What do you want from your mornings? | single | Get up on time · Stop scrolling first thing · Build a routine · Feel more awake | Primary goal; orders the task suggestions and the summary wording | Goal-setting / commitment nudges |
| 2 | What time do you need to be up on workdays? | time | dial | Alarm default; mid-sleep on workdays | MCTQ |
| 3 | What time do you usually fall asleep on workdays? | time | dial | Sleep duration estimate; a future bedtime reminder | MCTQ |
| 4 | Without an alarm, when do you wake up naturally? | time | dial | Chronotype (mid-sleep on free days) and **social jetlag** = gap to workdays | MCTQ |
| 5 | How do you wake up now? | single | First alarm · Snooze once or twice · Snooze 3+ times · Several alarms | Snooze allowance; how hard the wake-up task should be | Mattingly et al. 2022 (57% habitual snoozers) |
| 6 | In the first 30 minutes after waking, how do you feel? | single | Very tired · Fairly tired · Fairly refreshed · Very refreshed | Sleep inertia → start with a physical task (get up, walk) vs. a mental one | rMEQ item |
| 7 | When do you first pick up your phone after waking? | single | Before I'm out of bed · Within 10 minutes · Within 30 minutes · Later | How strict the morning lock is and how long it lasts | Phone-in-bed and morning-phone studies |
| 8 | How much time do you have before you need to leave or start? | single | Under 15 min · 15–30 min · 30–60 min · Over an hour | Routine length; how many tasks to suggest | Practical constraint |

**In the app now: 1, 2, 5, 7, 8.** Eight felt too long, so questions 3, 4 and 6 moved to the in-app list below. Question IDs and option IDs are in `apps/ios/loop/Features/Onboarding/Onboarding.swift`.

Then the existing steps: **set the alarm** (pre-filled from Q2), **choose apps** (replaces "What distracts you?"), **pick wake-up tasks** (pre-sorted using Q1, Q6 and Q8).

### Ask later, in the app (progressive profiling)

| When | Question | Why |
| --- | --- | --- |
| Day 2 | When do you usually fall asleep? (Q3) | Sleep duration |
| Day 2 | Without an alarm, when do you wake up? (Q4) | Chronotype and social jetlag |
| Day 4 | In the first 30 minutes after waking, how do you feel? (Q6) | Sleep inertia |
| After morning 1–3 | How did you feel this morning? (5-point, one tap) | The main outcome label for training |
| Day 3 | Rate your sleep over the past week (0–10 slider) | Single-Item Sleep Quality Scale; validated against the PSQI |
| Day 5 | Are you more of a morning or evening person? (Definitely morning · Rather morning · Rather evening · Definitely evening) | rMEQ item; cross-checks the chronotype from Q2–Q4 |
| Day 7 | How often do you use your phone in bed before sleeping? (Most nights · Some · Rarely) | Bedtime procrastination proxy; candidate for a future night feature |
| Any time | Any movement you'd rather skip? (multiple) | Safety and preference filter for physical tasks |

## Derived features (compute these, don't ask)

- **Sleep duration (workdays)** = Q2 − Q3.
- **Mid-sleep, workdays** = Q3 + duration / 2.
- **Chronotype estimate** = mid-sleep on free days (needs a free-day bedtime too; ask it later or estimate from Q4).
- **Social jetlag** = |mid-sleep, free days − mid-sleep, workdays|. Over 1h is a strong signal that mornings are hard regardless of motivation.
- **Sleep-debt flag** = workday duration under 7h.

## Data format recommendations

The backend stores `answers` as a JSON map, which is flexible. To make it model-ready:

- **Stable option IDs, not labels.** Store `"snooze_3_plus"`, not `"Snooze 3+ times"`, so copy changes and translations don't break the data.
- **Times as local minutes since midnight plus the IANA time zone** (`{"minutes": 420, "tz": "Europe/Amsterdam"}`), not a full `Date`. The question is a clock time, not a moment, and a `Date` shifts with time zones and DST.
- **Version the question set** (`"questionnaire_version": 2`) and store when each answer was given.
- **Record skips explicitly** as `null` rather than leaving the key out.
- **Store selected task IDs** in the onboarding upload. The app keeps them locally but doesn't send them yet.

## Daily signals to log (the real training data)

Per morning: scheduled alarm time · actual dismiss time · snooze count · time from alarm to first task start · tasks completed and skipped (with durations) · time apps unlocked · whether the lock was bypassed · the optional "how did you feel" tap.

From these the model can learn, per user, which tasks get people up fastest, how many snoozes to allow, and when a lock helps or just gets bypassed. That's where personalisation actually pays off.

## Caveats

- The rMEQ has modest internal consistency (α ≈ 0.6–0.7). Fine as a feature, not a diagnosis.
- Research linking morning or bedtime phone use with mood and sleep is mostly correlational.
- Evidence that light or exercise reduces grogginess at a normal wake time is mixed. Treat task effects as something to learn from each user's data, not assume.

## Sources

- [Reduced MEQ: Japanese validation](https://catalog.lib.kyushu-u.ac.jp/opac_download_md/7374719/Eto.etal_rMEQJ.pdf), [Swedish validation](https://pmc.ncbi.nlm.nih.gov/articles/PMC7372122), [Turkish validation](https://www.pubmed.gov/38629999/)
- [Munich ChronoType Questionnaire](https://en.wikipedia.org/wiki/Munich_Chronotype_Questionnaire); [Chronotype and social jetlag review](https://pubmed.ncbi.nlm.nih.gov/31336976/); [µMCTQ](https://pmc.ncbi.nlm.nih.gov/articles/PMC6784249)
- [Single-Item Sleep Quality Scale (Snyder et al. 2018)](https://pmc.ncbi.nlm.nih.gov/articles/PMC6223557)
- [Snoozing study (Mattingly et al., Sleep 2022)](https://www.sciencedaily.com/releases/2022/10/221017174902.htm); [snooze and sleep inertia](https://link.springer.com/article/10.1186/s40101-022-00317-w)
- [Smartphone use, bedtime procrastination and sleep quality](https://pmc.ncbi.nlm.nih.gov/articles/PMC10604906); [phone use in bed vs. outside bed](https://link.springer.com/article/10.1007/s00779-022-01694-w)
- [Morning phone use and stress](https://www.psychologicalscience.org/conventions/archive/2021icps/paper/34579/)
- [Sleep inertia and light at habitual wake time (NASA)](https://ntrs.nasa.gov/citations/20250005248); [Exercise and sleep inertia](https://www.frontiersin.org/articles/10.3389/fphys.2020.00254/pdf)
- [Implementation intentions and reminders](https://pmc.ncbi.nlm.nih.gov/articles/PMC5730820); [Behavioural science in onboarding](https://thedecisionlab.com/guides/how-behavioral-science-can-improve-customer-onboarding)
- [Preference elicitation for cold start (Sepliarskaia et al.)](https://irlab.science.uva.nl/wp-content/papercite-data/pdf/sepliarskaia-preference-2018.pdf); [Low-effort onboarding elicitation (Microsoft)](https://microsoft.com/en-us/research/uploads/prod/2020/10/who.does_.not_.like_.dinosaurs.pdf)
