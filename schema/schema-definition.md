# Schema Definition

## 1. Renters

**Role:** Actor

**Relation schema:**  
`Renters(renter_id, display_name, first_name, last_name, email, is_active, date_created)`

| Attribute | Domain | Description |
|---|---|---|
| `renter_id` | `INTEGER` | Unique identifier for each renter |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank | Name displayed for the renter on the platform |
| `first_name` | `VARCHAR` Variable length up to 50 characters | Renter's first name |
| `last_name` | `VARCHAR` Variable length up to 50 characters | Renter's last name |
| `email` | `VARCHAR` Variable length up to 100 characters; cannot be blank; no duplicate | Renter's email address |
| `is_active` | `BOOLEAN` | Indicates whether the renter account is currently active |
| `date_created` | `TIMESTAMP` | Date and time the renter account was created |

**Primary key:** `renter_id`

---

## 2. Properties

**Role:** Producer

**Relation schema:**  
`Properties(property_id, display_name, is_available, rent_amount, address_line1, address_line2, city, state, zip_code, country, date_created)`

| Attribute | Domain | Description |
|---|---|---|
| `property_id` | `INTEGER` | Unique identifier for each property |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank | Name or title displayed for the property |
| `is_available` | `BOOLEAN` | Indicates whether the property is currently available |
| `rent_amount` | `DECIMAL` with two digits after the decimal point; cannot be blank; greater than 0 | Rental price |
| `address_line1` | `VARCHAR` Variable length up to 255 characters | Primary street-address line |
| `address_line2` | `VARCHAR` Variable length up to 255 characters | Optional secondary address information |
| `city` | `VARCHAR` Variable length up to 100 characters | City where the property is located |
| `state` | `VARCHAR` Variable length up to 50 characters | State, province, or region where the property is located |
| `zip_code` | `VARCHAR` Variable length up to 50 characters | ZIP or postal code for the property |
| `country` | `VARCHAR` Variable length up to 100 characters | Country where the property is located |
| `date_created` | `TIMESTAMP` | Date and time the property record was created |

**Primary key:** `property_id`

---

## 3. Viewings

**Role:** Event

**Relation schema:**  
`Viewings(viewing_id, renter_id, property_id, viewed_at, duration_min)`

| Attribute | Domain | Description |
|---|---|---|
| `viewing_id` | `INTEGER` | Unique identifier for each viewing |
| `renter_id` | `INTEGER` | Identifier of the renter who viewed the property |
| `property_id` | `INTEGER` | Identifier of the property that was viewed |
| `viewed_at` | `TIMESTAMP` cannot be blank | Date and time when the viewing occurred |
| `duration_min` | `INTEGER` cannot be blank | Length of the viewing in minutes |

**Primary key:** `viewing_id`

**Foreign keys:**

- `renter_id` references `Renters(renter_id)`.
- `property_id` references `Properties(property_id)`.

---

## 4. Amenities

**Role:** Catalog

**Relation schema:**  
`Amenities(amenity_id, display_name)`

| Attribute | Domain | Description |
|---|---|---|
| `amenity_id` | `INTEGER` | Unique identifier for each amenity |
| `display_name` | `VARCHAR` Variable length up to 100 characters; cannot be blank; no duplicate | Name of the amenity displayed on the platform |

**Primary key:** `amenity_id`

---

## 5. Listing Amenities

**Role:** Junction

**Relation schema:**  
`Listing_Amenities(property_id, amenity_id)`

| Attribute | Domain | Description |
|---|---|---|
| `property_id` | `INTEGER` | Identifier of the property |
| `amenity_id` | `INTEGER` | Identifier of the amenity assigned to the property |

**Composite primary key:** (`property_id`, `amenity_id`)

**Foreign keys:**

- `property_id` references `Properties(property_id)`.
- `amenity_id` references `Amenities(amenity_id)`.