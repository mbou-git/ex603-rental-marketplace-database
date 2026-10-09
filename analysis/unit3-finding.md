# To the Dashboard Team

The dashboard says about half of all viewings end in failure, and that's why this quarter's agent commissions got frozen. The real numbers don't support that. Out of 200 viewings: 
* 156 were attended, 
* 34 were cancelled,
* 10 are marked "disputed" — not a confirmed failure. 
Even counting cancelled and disputed together as failures, that's 44 out of 200, or 22%. Not half.

Here's how I think the error happened. A query that excludes one specific reason by name (like "renter no-show") can end up excluding every record that has no reason logged because comparing against a blank field doesn't work the way people expect, and nothing about it throws an error. 
I tested this on the actual data: a filter for "not a renter no-show" returned 22 records, and a separate check for "no reason logged" returned 166. Added together that's 188, twelve short of 200. Those twelve just disappeared from the count, with no warning.

I'd release the frozen commissions. 22% isn't half, and the 10 disputed viewings shouldn't count as failures by default — they're open cases, not no-shows. Folding them in just makes the number worse. 
The query needs to count every viewing by its actual status instead of filtering out one label at a time.
