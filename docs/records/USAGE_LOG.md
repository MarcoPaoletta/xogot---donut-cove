# Usage log

How much of the plan this build uses, measured, in the order that matters.

1. Assets: free CC0 Quaternius packs, no generation credits are spent by this build.
2. Plan quota: Marco's /usage readings, shared with every other session running at the same time, so a
   percentage difference between two snapshots is an upper bound for this build, never an exact share.
3. Exact tokens per agent, read from the transcripts by `tools/usage_snapshot.py`: the part attributable to this build.

The flat plan fee is not a project cost and no API list price is quoted here as one.

## build start
Snapshot at 2026-11-11 18:59 UTC (15:59 -0300 local). Sessions counted from 2026-11-11T15:59:35.

| Agent | Messages | Input | Cache write | Cache read | Output | First | Last |
| :-- | --: | --: | --: | --: | --: | :-- | :-- |
| **All agents** | 0 | 0 | 0 | 0 | 0 | | |

## M0
Snapshot at 2026-11-11 19:08 UTC (16:08 -0300 local). Sessions counted from 2026-11-11T15:59:35.

| Agent | Messages | Input | Cache write | Cache read | Output | First | Last |
| :-- | --: | --: | --: | --: | --: | :-- | :-- |
| **All agents** | 0 | 0 | 0 | 0 | 0 | | |

## M2
Snapshot at 2026-11-11 19:56 UTC (16:56 -0300 local). Sessions counted from 2026-11-11T15:59:35.

| Agent | Messages | Input | Cache write | Cache read | Output | First | Last |
| :-- | --: | --: | --: | --: | --: | :-- | :-- |
| **All agents** | 0 | 0 | 0 | 0 | 0 | | |

## build end
Snapshot at 2026-11-11 22:18 UTC (19:18 -0300 local). Sessions counted from 2026-11-11T15:40.

| Agent | Messages | Input | Cache write | Cache read | Output | First | Last |
| :-- | --: | --: | --: | --: | --: | :-- | :-- |
| lead session 83be5f8d | 255 | 516 | 950,080 | 141,422,591 | 497,694 | 2026-11-11T18:40 | 2026-11-11T22:18 |
| **All agents** | 255 | 516 | 950,080 | 141,422,591 | 497,694 | | |

API pricing equivalent of the tokens above at 8,16,0.20,40 USD per million: 63.40 USD. Not what was paid: the plan is a flat subscription shared by every project of the user.

Lead session started 15:40 for the xo setup, 19 minutes before the build start at 15:59:35, so these totals include the setup and the wait for the GDD (upper bound for the build). Prices read on 2026-11-11 from platform.claude.com/docs/en/about-claude/pricing for Claude Fable 5.2: input 8, cache write 16 (1 hour; 5 minute writes are 10), cache read 0.20, output 40 USD per million tokens. Marco's /usage reading was not given.
