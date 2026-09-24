# DDL Reasoning

## The supertype/subtype design

`accounts` holds the fields every account holder shares — `display_name`, `first_name`, `last_name`, `email`, `account_active`, `date_created`, and `referred_by`. `renters` and `landlords` are subtypes: their primary key is also a foreign key back to `accounts`, so a renter or landlord row can't exist without an account behind it. I made the two roles overlapping rather than exclusive, since someone could rent a place while also listing one of their own, so nothing stops an account from having both a `renters` row and a `landlords` row. Each subtype keeps its own `is_active` flag and its own `referral_discount_used_at`, separate from the account-level `account_active`, because someone could pause their landlord listings without touching their renter activity, or redeem a referral discount as a renter without it meaning anything on the landlord side.

`properties.listed_at` isn't the same as `date_created` — it tracks when the *current* listing started, and a trigger resets it whenever `is_available` flips back to true, so a property that gets rented out and relisted later doesn't inherit the time it spent off the market. "Days listed" itself isn't stored anywhere; I compute it at query time as `CURRENT_DATE - listed_at`. `property_price_history` logs the old `rent_amount` whenever it changes, using a second trigger; its primary key is `(property_id, changed_at)`, since a timestamp on its own doesn't identify anything — it only means something next to the property it belongs to, which makes it a weak entity. Last, `properties` has a unique constraint on the full address, including a new `unit_number` column, so the same listing can't be entered twice while still letting different units in the same building be separate rows.

## The constraints table

| Foreign key | ON DELETE | Reason |
|---|---|---|
| `fk_accounts_referred_by` (`accounts.referred_by` → `accounts.account_id`) | SET NULL | Deleting the account that referred someone shouldn't delete the account it referred. |
| `fk_renters_account` (`renters.account_id` → `accounts.account_id`) | CASCADE | A renter row only exists to mark a role on its account; once the account is gone there's nothing left for it to describe. |
| `fk_landlords_account` (`landlords.account_id` → `accounts.account_id`) | CASCADE | A landlord row only exists to mark a role on its account; once the account is gone there's nothing left for it to describe. |
| `fk_properties_landlord` (`properties.landlord_id` → `landlords.account_id`) | RESTRICT | A property always needs a traceable owner. |
| `fk_viewings_renter` (`viewings.renter_id` → `renters.account_id`) | RESTRICT | Viewing history needs to stay attributable, so a renter with recorded viewings can't be removed. |
| `fk_viewings_property` (`viewings.property_id` → `properties.property_id`) | RESTRICT | Viewing history needs to stay attributable, so a property with recorded viewings can't be removed. |
| `fk_listing_amenities_property` (`listing_amenities.property_id` → `properties.property_id`) | CASCADE | The row only exists to link a property to an amenity, so it has no meaning once the property is gone. |
| `fk_listing_amenities_amenity` (`listing_amenities.amenity_id` → `amenities.amenity_id`) | CASCADE | The row only exists to link a property to an amenity, so it has no meaning once the amenity is gone. |
| `fk_reviews_viewing` (`reviews.viewing_id` → `viewings.viewing_id`) | CASCADE | A review only means something attached to the viewing it's about. |
| `fk_property_price_history_property` (`property_price_history.property_id` → `properties.property_id`) | CASCADE | A price history row only means something attached to the property it describes. |

`fk_accounts_referred_by` is SET NULL because deleting the account that referred someone shouldn't impact the account it referred. RESTRICT would block deleting anyone who'd ever referred someone else, and CASCADE would take their whole referral chain down with them.

A renter or landlord row only exists to mark a role on an account, so `fk_renters_account` and `fk_landlords_account` cascade — once the account's gone, there's nothing left for that role to attach to. RESTRICT would block deleting an account that simply signed up for a role and never used it, though anything with real activity already gets stopped by the RESTRICT rules below.

A property can't be ownerless, so `fk_properties_landlord` is RESTRICT: a landlord can't be deleted while they still own properties. CASCADE would take their whole portfolio down with them, and SET NULL would leave a property with no owner, which doesn't make sense. Deactivating the landlord instead keeps everything intact.

`fk_viewings_renter` and `fk_viewings_property` are RESTRICT for the same kind of reason: deleting a renter or property with viewing history would break that history — CASCADE erases it, SET NULL leaves it pointing at nothing. Marking the renter inactive or the property unavailable keeps the record intact instead.

A `listing_amenities` row only links a property to an amenity, so `fk_listing_amenities_property` and `fk_listing_amenities_amenity` cascade — once either side is gone, the link is meaningless. RESTRICT would just force clearing it out by hand first, for no real benefit.

`fk_reviews_viewing` cascades because a review only makes sense next to the viewing it's about. RESTRICT would block cleaning up a bad viewing record just because a review is attached to it, and SET NULL would leave the review orphaned with nothing to point to.

`fk_property_price_history_property` cascades for the same reason — a price history row means nothing without its property. RESTRICT would make a property with even one rent change permanently undeletable, and SET NULL isn't even possible here, since `property_id` is part of the primary key.

## The CHECK constraints

`chk_accounts_no_self_referral` stops `referred_by` from equaling `account_id`, so an account can't refer itself. Without it, a signup bug that defaults the referral field to the new account's own id would go unnoticed.

`chk_properties_rent_amount_positive` blocks a rent of zero or less. That's not a real listing — more likely an incomplete form submitted before the owner entered a price, or an import that mapped a missing price to zero instead of rejecting the row.

`chk_viewings_duration_positive` blocks a viewing duration of zero or less the same way. That usually points to a bug in whatever's timing the viewing — clock skew producing a negative interval, or an event that never captured a proper start and end.

`chk_viewings_not_future` stops `viewed_at` from being later than the current time, since a viewing is something that's already happened by the time it's logged. That state could otherwise arise from a client submitting a scheduled, upcoming viewing as if it had already happened.

`chk_properties_year_built_range` blocks a `year_built` outside 1800–2100 — a value like `0` or `3000` doesn't correspond to any real construction date, and could arise from a free-text year field or an import that misreads a two-digit year. I left the column nullable, since a landlord genuinely might not know when an older building was built.

`chk_reviews_rating_range` keeps `rating` between 1 and 5, matching the five-point scale the app actually uses. Without it, a bad UI control, or an API call that skips client-side validation entirely, could store a rating like `0` or `27` that doesn't correspond to anything on that scale.

`chk_reviews_low_rating_requires_comment` requires a comment whenever the rating is below 3. A bad rating with nothing behind it isn't very useful to anyone reading it, landlord or future renter, and it's an easy state to end up in if a submission form treats the comment box as optional no matter what rating was picked.

`chk_property_price_history_amount_positive` keeps `previous_rent_amount` positive too. It's a bit redundant since the value is only ever copied from `properties.rent_amount` by the trigger, which already enforces the same rule — but I kept it in case anything ever inserts into this table directly.

## What changed since Unit 1

Writing the actual DDL surfaced a few gaps the Unit 1 ERD didn't cover. I updated `schema/erd.mmd` (and `schema/erd.png`) to match rather than leave the two out of step; here's what changed and why:

- **Landlords didn't exist.** The Unit 1 design had `renters` and `properties`, but no owner for a property — nothing could answer "whose listing is this." I split the original renter relation into a shared `accounts` supertype with `renters` and `landlords` as subtypes, so an account can hold either role, or both.
- **No recursive foreign key.** Adding referrals (`accounts.referred_by`) gave the design its one self-referencing relationship, which nothing in the Unit 1 ERD had.
- **No weak entity.** `property_price_history` is new — a rent-change log keyed by `(property_id, changed_at)` — and it's the one relation in the schema that's existence-dependent on another with no identity of its own.
- **Reviews didn't exist.** Renters had no way to leave feedback on a property after viewing it, so `reviews` is a new relation, tied to the viewing it followed.
- **`properties` picked up a few attributes along the way**: `year_built`, `unit_number` (needed once I added a uniqueness constraint on address, to keep separate units at the same address from colliding), and `listed_at` (separate from `date_created`, since a relisted property shouldn't inherit how long it was previously off the market).

None of this changes the domain from Unit 1 — it's the same rental marketplace — but the original five-relation design left the landlord side of it out entirely, and that only became obvious once I tried to write DDL that actually enforced ownership.
