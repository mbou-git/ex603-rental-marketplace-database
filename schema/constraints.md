# Integrity Constraints

## renters

- `renter_id` is the primary key. It must be unique and cannot be null.
- `display_name` cannot be null.
- `email` must be unique so that the same email address cannot be used for multiple accounts.
- `is_active` must be either true or false, default to true.
- `date_created` should be updated by a trigger when a record is inserted.

## properties

- `property_id` is the primary key. It must be unique and cannot be null.
- `display_name` cannot be null.
- `rent_amount` must be greater than zero and cannot be null.
- `is_available` must be either true or false, default to true.
- `date_created` should be updated by a trigger when a record is inserted.

## viewings

- `viewing_id` is the primary key. It must be unique and cannot be null.
- `renter_id`, `property_id`, `viewed_at`, and `duration_min` cannot be null.
- `duration_min` must be greater than zero.
- `viewed_at` cannot be in the future.

### Foreign keys

- `renter_id` references `renters.renter_id` with **ON DELETE RESTRICT**. A renter cannot be deleted while viewing records still reference that renter. This prevents orphaned records and preserves viewing history. It should be marked inactive instead.
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