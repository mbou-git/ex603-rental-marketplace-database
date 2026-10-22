# Unit 4 Analysis

## Task 4.1: The per-producer breakdown

The agent managing a property would act on this. They'd decide whether it needs new photos, a price change, or a conversation with the owner about low interest.

The average hides the spread. Two properties can have the same `avg_duration_min` for different reasons — one where every viewing runs close to that number, one built from a mix of multiple short visits and one very long. You can't tell which from the average alone.

The count hides who's looking. 18 viewings could be 18 different renters checking once each, or 3 renters coming back 6 times, still undecided. Same number, different situation, and `viewings_count` can't tell them apart.

Next I'd want: the spread of `duration_min` per property, and `COUNT(DISTINCT renter_id)` per property — same thing `4.1.1` already computes platform-wide, just broken out per property.

## Task 4.2: The breakdown leadership asked for

**Part A.** How much activity does this property get, and how much of that activity ended in failure? `viewings_count` answers the first, `failed_count` answers the second, computed together instead of two separate filtered queries.

**Part B.** The regional director needs the subtotals, not the detail rows — they're managing a region, not 15 individual properties. The grand total answers a different, platform-wide question the per-region subtotals can't: is the overall failure rate a company-wide problem, not just a problem in one or two regions? A region's own subtotal only tells that director how their region is doing; it can't tell leadership whether to act platform-wide.

**Part C.** The pipeline answers: among properties with enough viewings for their rate to mean anything, what counts as normal? That's the number an individual high-volume property's own failure rate gets compared against to decide whether it's actually an outlier or just ordinary variation.

## Reflection

Conditional aggregation scans the table once and fills in several answers as it goes — `viewings_count` and `failed_count` came out of the same single pass over `viewings` in `4.2a`. Two separate filtered queries would scan the table twice, once per question.

At 200 rows that costs nothing, which is why it's easy not to notice. At a million rows it's a second full read of the table, and the cost keeps climbing with every extra question — five conditions means five scans for the two-query approach, one scan either way for conditional aggregation.

There's a correctness problem too, not just a speed one. Run two queries while the table is being written to, and they can land on different moments in time — the total from query one and the failure count from query two might not describe the same snapshot anymore. They could stop adding up and nothing would tell you. A single pass can't have that problem, since every number it returns comes from the same read.
