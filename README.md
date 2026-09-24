# Rental Marketplace Database
A relational database for managing a rental marketplace, including renter and landlord accounts, viewings, property amenities, and reviews.

**Author:** Mohamed Bouattour

**Chosen theme:** Rental Marketplace

## Domain

This project models the data needed by a rental marketplace. 
The database holds renter and landlord accounts, the properties landlords list, and tracks viewings, amenities, and reviews for each property.

Properties can offer multiple amenities that can be associated with many properties. 
A renter can go to multiple viewings, and an account can be a renter, a landlord, or both.

The database should be able to answer questions such as:
- What's the rent amount for available properties and where are they located?
- What are all the amenities offered by a particular property and which properties have a particular amenity?
- Which properties has a renter viewed? Which renters viewed a specific property? How often was a property viewed, and how much time did renters spend viewing it?
- How has a property's rent changed over time?
- What's the average rating for a property, based on renter reviews?


## Schema

Nine relations: `accounts` (with `renters` and `landlords` as subtypes), `properties`, `property_price_history`, `amenities`, `listing_amenities`, `viewings`, and `reviews`.

Worth noticing: `renters` and `landlords` overlap rather than being mutually exclusive, `accounts.referred_by` is a self-referencing foreign key, `property_price_history` is a weak entity, and deletions are `RESTRICT`ed (with an `is_active`/`is_available` flag instead) wherever history needs to survive.

Full details in [`schema/schema-definition.md`](schema/schema-definition.md) and [`schema/constraints.md`](schema/constraints.md).

## Entity Relationship Diagram

![Rental Marketplace Entity Relationship Diagram](schema/erd.png)
