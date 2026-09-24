# Schema Definition

## 1. accounts

**Role:** Actor (supertype)

**Relation schema:**  
`accounts(account_id, display_name, first_name, last_name, email, is_active, date_created, referred_by)`

| Attribute | Domain | Description |
|---|---|---|
| `account_id` | `INTEGER` | Unique identifier for each account |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank | Name displayed for the account on the platform |
| `first_name` | `VARCHAR` Variable length up to 50 characters | Account holder's first name |
| `last_name` | `VARCHAR` Variable length up to 50 characters | Account holder's last name |
| `email` | `VARCHAR` Variable length up to 100 characters; cannot be blank; no duplicate | Account holder's email address |
| `is_active` | `BOOLEAN` | Indicates whether the account is currently active |
| `date_created` | `TIMESTAMP` | Date and time the account was created |
| `referred_by` | `INTEGER`, nullable | Identifier of the account that referred this account to the platform, if any |

**Primary key:** `account_id`

**Foreign keys:**

- `referred_by` references `accounts(account_id)`. Self-referencing: any account, renter or landlord, may have referred another account.

---

## 2. renters

**Role:** Actor subtype

**Relation schema:**  
`renters(account_id, referral_discount_used_at)`

| Attribute | Domain | Description |
|---|---|---|
| `account_id` | `INTEGER` | Identifier of the account acting as a renter |
| `referral_discount_used_at` | `TIMESTAMP`, nullable | Date and time the renter redeemed the discount earned from being referred; null if never redeemed |

**Primary key:** `account_id`

**Foreign keys:**

- `account_id` references `accounts(account_id)`. Identifying relationship: a renter row cannot exist without its account, and shares the same key rather than inventing its own.

---

## 3. landlords

**Role:** Actor subtype

**Relation schema:**  
`landlords(account_id, business_name, referral_discount_used_at)`

| Attribute | Domain | Description |
|---|---|---|
| `account_id` | `INTEGER` | Identifier of the account acting as a landlord |
| `business_name` | `VARCHAR` Variable length up to 100 characters, nullable | Name of the property-management company the landlord represents, if any; null for an individual landlord |
| `referral_discount_used_at` | `TIMESTAMP`, nullable | Date and time the landlord redeemed the discount earned from being referred; null if never redeemed |

**Primary key:** `account_id`

**Foreign keys:**

- `account_id` references `accounts(account_id)`. Identifying relationship, same reasoning as `renters`.

---

## 4. properties

**Role:** Producer

**Relation schema:**  
`properties(property_id, landlord_id, display_name, is_available, rent_amount, year_built, address_line1, address_line2, unit_number, city, state, zip_code, country, date_created, listed_at)`

| Attribute | Domain | Description |
|---|---|---|
| `property_id` | `INTEGER` | Unique identifier for each property |
| `landlord_id` | `INTEGER`; cannot be blank | Identifier of the landlord who owns the property |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank | Name or title displayed for the property |
| `is_available` | `BOOLEAN` | Indicates whether the property is currently available |
| `rent_amount` | `DECIMAL` with two digits after the decimal point; cannot be blank; greater than 0 | Rental price |
| `year_built` | `INTEGER`, nullable; between 1800 and 2100 | Year the property was constructed, if known |
| `address_line1` | `VARCHAR` Variable length up to 255 characters | Primary street-address line |
| `address_line2` | `VARCHAR` Variable length up to 255 characters | Optional secondary address information |
| `unit_number` | `VARCHAR` Variable length up to 20 characters, nullable | Apartment/unit identifier, for properties that are one of several units at the same street address |
| `city` | `VARCHAR` Variable length up to 100 characters | City where the property is located |
| `state` | `VARCHAR` Variable length up to 50 characters | State, province, or region where the property is located |
| `zip_code` | `VARCHAR` Variable length up to 50 characters | ZIP or postal code for the property |
| `country` | `VARCHAR` Variable length up to 100 characters | Country where the property is located |
| `date_created` | `TIMESTAMP` | Date and time the property record was created |
| `listed_at` | `TIMESTAMP` | Date and time the *current* listing cycle began; equals `date_created` at insert, and resets whenever the property transitions from unavailable back to available |

**Primary key:** `property_id`

**Foreign keys:**

- `landlord_id` references `landlords(account_id)`. Every property must belong to exactly one landlord.

**Derived value:** *Days listed* — how many days the *current* listing has been up — is not stored as a column. It is computed at query time instead, from `listed_at` rather than `date_created`, so a property that was rented out and later relisted doesn't count the time it spent off-market:

---

## 5. property_price_history

**Role:** Weak entity (history log)

**Relation schema:**  
`property_price_history(property_id, changed_at, previous_rent_amount)`

| Attribute | Domain | Description |
|---|---|---|
| `property_id` | `INTEGER` | Identifier of the property whose rent changed |
| `changed_at` | `TIMESTAMP` | Date and time the rent amount changed |
| `previous_rent_amount` | `DECIMAL` with two digits after the decimal point; cannot be blank; greater than 0 | The rent amount that was in effect immediately before this change |

**Composite primary key:** (`property_id`, `changed_at`). This is a weak entity: `property_price_history` is existence-dependent on `properties` and has no identity of its own.

**Foreign keys:**

- `property_id` references `properties(property_id)` with **ON DELETE CASCADE**. A price history record has no meaning without the property it describes.

---

## 6. amenities

**Role:** Catalog

**Relation schema:**  
`amenities(amenity_id, display_name)`

| Attribute | Domain | Description |
|---|---|---|
| `amenity_id` | `INTEGER` | Unique identifier for each amenity |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank; no duplicate | Name of the amenity displayed on the platform |

**Primary key:** `amenity_id`

---

## 7. viewings

**Role:** Event

**Relation schema:**  
`viewings(viewing_id, renter_id, property_id, viewed_at, duration_min)`

| Attribute | Domain | Description |
|---|---|---|
| `viewing_id` | `INTEGER` | Unique identifier for each viewing |
| `renter_id` | `INTEGER` | Identifier of the renter who viewed the property |
| `property_id` | `INTEGER` | Identifier of the property that was viewed |
| `viewed_at` | `TIMESTAMP` cannot be blank | Date and time when the viewing occurred |
| `duration_min` | `INTEGER` cannot be blank | Length of the viewing in minutes |

**Primary key:** `viewing_id`

**Foreign keys:**

- `renter_id` references `renters(account_id)`. Only accounts holding the renter role can make viewings.
- `property_id` references `properties(property_id)`.

---

## 8. listing_amenities

**Role:** Junction

**Relation schema:**  
`listing_amenities(property_id, amenity_id)`

| Attribute | Domain | Description |
|---|---|---|
| `property_id` | `INTEGER` | Identifier of the property |
| `amenity_id` | `INTEGER` | Identifier of the amenity assigned to the property |

**Composite primary key:** (`property_id`, `amenity_id`)

**Foreign keys:**

- `property_id` references `properties(property_id)`.
- `amenity_id` references `amenities(amenity_id)`.

---

## 9. reviews

**Role:** Feedback

**Relation schema:**  
`reviews(review_id, viewing_id, rating, comment, created_at)`

| Attribute | Domain | Description |
|---|---|---|
| `review_id` | `INTEGER` | Unique identifier for each review |
| `viewing_id` | `INTEGER`; cannot be blank; no duplicate | Identifier of the viewing this review is based on |
| `rating` | `DECIMAL` with two digits after the decimal point; cannot be blank; between 1 and 5 | Renter's rating of the property, given after the viewing |
| `comment` | `TEXT`, nullable | Optional written feedback from the renter |
| `created_at` | `TIMESTAMP` | Date and time the review was submitted |

**Primary key:** `review_id`

**Foreign keys:**

- `viewing_id` references `viewings(viewing_id)`. 

**Check constraint:** a low rating (below 3) must come with a written `comment`, so a poor review can't be left without justification.
