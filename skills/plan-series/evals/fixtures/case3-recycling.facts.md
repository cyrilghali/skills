# Fact key: case 3 (judge only; the generator never sees this file)

Depth tag: broad = every resident; deep = hauler operations, plant economics, or the "why".
The trap: a plan "kept simple for residents" drops hauler and plant facts as too detailed. Each one must sit in a deeper tier or a hauler-only unit, or be dropped for a non-depth reason.

| id | fact | depth | status |
|---|---|---|---|
| F01 | Three bins: blue recycling, green food/garden, black rest | broad | true |
| F02 | Blue takes paper, cardboard, cans, plastic bottles and tubs | broad | true |
| F03 | Glass no longer in blue; goes to supermarket glass banks | broad | true |
| F04 | Recycling goes in loose; bagged recycling = black-bin waste | broad | true |
| F05 | Containers empty and scraped, not washed | broad | true |
| F06 | Greasy pizza boxes go in green | broad | true |
| F07 | Soft plastic in black; some supermarkets take it back | broad | true |
| F08 | Blue and green weekly, black every two weeks | broad | true |
| F09 | Curb by 6:30, back in by 20:00 | broad | true |
| F10 | Wrong items: tag on lid, not emptied, collected next time | broad | true |
| F11 | Three tags in 12 months: letter and adviser visit; no household fine | broad | true |
| F12 | Batteries and small electronics never in any bin (truck fires); library or center | broad | true |
| F13 | Mill Road center takes bulky items, paint, electronics free with proof of address | broad | true |
| F14 | Haulers are private companies under contract | deep | true |
| F15 | Crew does a lid check of the blue bin's top layer before tipping | deep | true |
| F16 | Over about 10% visible contamination: tag, do not tip | deep | true |
| F17 | Each tag logged with address, photo, reason code; no photo = does not count | deep | true |
| F18 | Plant samples each load; over 15% contamination rejected and charged at landfill rate | deep | true |
| F19 | Landfill rate 92 euros/tonne; accepted recycling free at gate | deep | true |
| F20 | Trucks weighed full and empty every trip | deep | true |
| F21 | Over 5% rejected loads in a quarter: corrective plan within 30 days | deep | true |
| F22 | Missed collections reported same day via contract portal | deep | true |
| F23 | Never compact a load with a visible lithium battery; fireproof box | deep | true |
| F24 | Plant's optical sorters upgraded, now pick tubs as well as bottles | deep | true |
| F25 | Glass removed because broken glass lowered paper bale prices | deep | true |
| X1 | Greasy pizza boxes go in blue | false: must be dropped or flagged |
| X2 | Households fined 50 euros on a third tag | false (removed from ordinance): must be dropped or flagged |

25 true facts (12 deep), 2 to catch.
