# Integrity Constraints

## accounts

- `account_id` is the primary key. It must be unique and cannot be null.
- `display_name` cannot be null.
- `email` must be unique so that the same email address cannot be used for multiple accounts.
- `is_active` must be either true or false, default to true.
- `date_created` defaults to the current timestamp when a record is inserted.
- `referred_by` is nullable, since not every account was referred.
- `referred_by` cannot equal `account_id`; an account cannot refer itself.

### Foreign keys

- `referred_by` references `accounts.account_id` (self-referencing) with **ON DELETE SET NULL**.

## renters

- `account_id` is the primary key. It must be unique and cannot be null.
- `referral_discount_used_at` is nullable; it is only set once the renter-side referral discount has been redeemed.

### Foreign keys

- `account_id` references `accounts.account_id` with **ON DELETE CASCADE**. 

## landlords

- `account_id` is the primary key. It must be unique and cannot be null.
- `business_name` is nullable, since an individual landlord has no company to name.
- `referral_discount_used_at` is nullable; it is only set once the landlord-side referral discount has been redeemed.

### Foreign keys

- `account_id` references `accounts.account_id` with **ON DELETE CASCADE**.

## properties

- `property_id` is the primary key. It must be unique and cannot be null.
- `landlord_id` cannot be null; every property must have an owner.
- `display_name` cannot be null.
- `rent_amount` must be greater than zero and cannot be null.
- `is_available` must be either true or false, default to true.
- `year_built` is nullable, since the construction year isn't always known; when present it must be between 1800 and 2100.
- `unit_number` is nullable, since a standalone property (e.g. a single-family house) has no unit to identify.
- `date_created` defaults to the current timestamp when a record is inserted.
- `listed_at` defaults to the current timestamp when a record is inserted, matching `date_created` for a newly created property.

### Foreign keys

- `landlord_id` references `landlords.account_id` with **ON DELETE RESTRICT**. A landlord cannot be deleted while they still own properties. The account should be marked inactive instead.

### Unique constraints

- (`address_line1`, `unit_number`, `city`, `state`, `zip_code`, `country`) must be unique together. This stops the same address being listed twice as separate properties.

### Trigger

- `trg_properties_relisted` (`BEFORE UPDATE`, calling `fn_properties_set_listed_at`) resets `listed_at` to the current timestamp whenever a row's `is_available` changes from `FALSE` to `TRUE`.
- `trg_properties_price_change` (`AFTER UPDATE`, calling `fn_properties_log_price_change`) fires whenever `rent_amount` actually changes, logging the previous value into `property_price_history`.

## property_price_history

- The combination of `property_id` and `changed_at` is the composite primary key. 
- Both key attributes cannot be null.
- `previous_rent_amount` cannot be null and must be greater than zero.
- Rows are only ever inserted by `trg_properties_price_change`; there's no direct application write path for this table.

### Foreign keys

- `property_id` references `properties.property_id` with **ON DELETE CASCADE**. A price history record has no meaning without the property it describes.

## viewings

- `viewing_id` is the primary key. It must be unique and cannot be null.
- `renter_id`, `property_id`, `viewed_at`, and `duration_min` cannot be null.
- `duration_min` must be greater than zero.
- `viewed_at` cannot be in the future.

### Foreign keys

- `renter_id` references `renters.account_id` with **ON DELETE RESTRICT**. A renter cannot be deleted while viewing records still reference them. This prevents orphaned records and preserves viewing history. The account should be marked inactive instead.
- `property_id` references `properties.property_id` with **ON DELETE RESTRICT**. A property with viewing history cannot be deleted. It should be marked unavailable instead so that its history is preserved.

## amenities

- `amenity_id` is the primary key. It must be unique and cannot be null.
- `display_name` cannot be null and must be unique. This prevents duplicate or unnamed amenities.

## listing_amenities

- The combination of `property_id` and `amenity_id` is the composite primary key.
- Both attributes cannot be null.
- The composite key prevents the same amenity from being assigned to the same property more than once.

### Foreign keys

- `property_id` references `properties.property_id` with **ON DELETE CASCADE**. If a property is deleted, its amenity associations should also be deleted because they no longer have meaning.
- `amenity_id` references `amenities.amenity_id` with **ON DELETE CASCADE**. If an amenity is deleted, its associations with properties should also be deleted.

## reviews

- `review_id` is the primary key. It must be unique and cannot be null.
- `viewing_id` cannot be null and must be unique, so a given viewing can be reviewed at most once.
- `rating` cannot be null and must be between 1 and 5.
- `rating` below 3 requires a non-null `comment`; a low rating must be justified in writing.
- `created_at` defaults to the current timestamp when a record is inserted.

### Foreign keys

- `viewing_id` references `viewings.viewing_id` with **ON DELETE CASCADE**. A review only has meaning attached to the viewing it was based on; if that viewing record is removed, the review is removed with it.