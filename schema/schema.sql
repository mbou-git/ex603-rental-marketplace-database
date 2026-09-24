-- =================================================================
-- EX 603 Assignment 2 — schema.sql
-- Theme: Rental Marketplace
-- Author: Mohamed Bouattour
-- Target: PostgreSQL 14+
-- =================================================================
-- Reset. Reverse creation order, so no dependency blocks a drop.

DROP TABLE IF EXISTS reviews               CASCADE;
DROP TABLE IF EXISTS listing_amenities     CASCADE;
DROP TABLE IF EXISTS viewings              CASCADE;
DROP TABLE IF EXISTS amenities             CASCADE;
DROP TABLE IF EXISTS property_price_history CASCADE;
DROP TABLE IF EXISTS properties            CASCADE;
DROP TABLE IF EXISTS landlords             CASCADE;
DROP TABLE IF EXISTS renters               CASCADE;
DROP TABLE IF EXISTS accounts              CASCADE;
DROP FUNCTION IF EXISTS fn_properties_set_listed_at() CASCADE;
DROP FUNCTION IF EXISTS fn_properties_log_price_change() CASCADE;

-- ----------------------------------------------------------------
-- 1. accounts — first; its only foreign key is recursive, so it
--    depends on nothing but itself. Supertype shared by renters
--    and landlords.
-- ----------------------------------------------------------------
CREATE TABLE accounts (
    account_id      INTEGER GENERATED ALWAYS AS IDENTITY,
    display_name    VARCHAR(100)  NOT NULL,
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    email           VARCHAR(100)  NOT NULL,
    account_active  BOOLEAN       NOT NULL DEFAULT TRUE,
    date_created    TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    referred_by     INTEGER,
    CONSTRAINT pk_accounts PRIMARY KEY (account_id),
    CONSTRAINT uq_accounts_email UNIQUE (email),
    CONSTRAINT fk_accounts_referred_by
        FOREIGN KEY (referred_by) REFERENCES accounts (account_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_accounts_no_self_referral
        CHECK (referred_by IS DISTINCT FROM account_id)
);

-- ----------------------------------------------------------------
-- 2. renters — second; subtype of accounts. Its primary key is
--    also its foreign key to the supertype (identifying
--    relationship), not a new id.
-- ----------------------------------------------------------------
CREATE TABLE renters (
    account_id                  INTEGER    NOT NULL,
    is_active                   BOOLEAN    NOT NULL DEFAULT TRUE,
    referral_discount_used_at   TIMESTAMP,
    CONSTRAINT pk_renters PRIMARY KEY (account_id),
    CONSTRAINT fk_renters_account
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
        ON DELETE CASCADE
);

-- ----------------------------------------------------------------
-- 3. landlords — third; subtype of accounts, same pattern as
--    renters.
-- ----------------------------------------------------------------
CREATE TABLE landlords (
    account_id                  INTEGER       NOT NULL,
    is_active                   BOOLEAN       NOT NULL DEFAULT TRUE,
    business_name               VARCHAR(100),
    referral_discount_used_at   TIMESTAMP,
    CONSTRAINT pk_landlords PRIMARY KEY (account_id),
    CONSTRAINT fk_landlords_account
        FOREIGN KEY (account_id) REFERENCES accounts (account_id)
        ON DELETE CASCADE
);

-- ----------------------------------------------------------------
-- 4. properties — fourth; references landlords.
--    Derived value: "days listed" is not stored here. 
--    It is computed at query time instead
-- ----------------------------------------------------------------
CREATE TABLE properties (
    property_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    landlord_id    INTEGER        NOT NULL,
    display_name   VARCHAR(100)   NOT NULL,
    is_available   BOOLEAN        NOT NULL DEFAULT TRUE,
    rent_amount    NUMERIC(10,2)  NOT NULL,
    year_built     INTEGER,
    address_line1  VARCHAR(255),
    address_line2  VARCHAR(255),
    unit_number    VARCHAR(20),
    city           VARCHAR(100),
    state          VARCHAR(50),
    zip_code       VARCHAR(50),
    country        VARCHAR(100),
    date_created   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    listed_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_properties PRIMARY KEY (property_id),
    CONSTRAINT fk_properties_landlord
        FOREIGN KEY (landlord_id) REFERENCES landlords (account_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_properties_rent_amount_positive CHECK (rent_amount > 0),
    CONSTRAINT chk_properties_year_built_range
        CHECK (year_built IS NULL OR year_built BETWEEN 1800 AND 2100),
    CONSTRAINT uq_properties_address
        UNIQUE (address_line1, unit_number, city, state, zip_code, country)
);

-- On insert, listed_at defaults to CURRENT_TIMESTAMP, the same value
-- date_created receives.
-- On update, this trigger resets listed_at only when is_available
-- flips from FALSE to TRUE.
CREATE FUNCTION fn_properties_set_listed_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.listed_at := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_properties_relisted
    BEFORE UPDATE ON properties
    FOR EACH ROW
    WHEN (OLD.is_available = FALSE AND NEW.is_available = TRUE)
    EXECUTE FUNCTION fn_properties_set_listed_at();

-- ----------------------------------------------------------------
-- 5. property_price_history — fifth; references properties. A
--    price history record has no meaning without the property it
--    describes, hence the composite key and ON DELETE CASCADE.
-- ----------------------------------------------------------------
CREATE TABLE property_price_history (
    property_id            INTEGER        NOT NULL,
    changed_at             TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    previous_rent_amount   NUMERIC(10,2)  NOT NULL,
    CONSTRAINT pk_property_price_history PRIMARY KEY (property_id, changed_at),
    CONSTRAINT fk_property_price_history_property
        FOREIGN KEY (property_id) REFERENCES properties (property_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_property_price_history_amount_positive
        CHECK (previous_rent_amount > 0)
);

-- Logs the old rent_amount whenever it actually changes. 
-- AFTER UPDATE, not BEFORE, since this writes to
-- a different table as a side effect rather than modifying the row
-- being updated.
CREATE FUNCTION fn_properties_log_price_change()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO property_price_history (property_id, changed_at, previous_rent_amount)
    VALUES (OLD.property_id, CURRENT_TIMESTAMP, OLD.rent_amount);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_properties_price_change
    AFTER UPDATE ON properties
    FOR EACH ROW
    WHEN (OLD.rent_amount IS DISTINCT FROM NEW.rent_amount)
    EXECUTE FUNCTION fn_properties_log_price_change();

-- ----------------------------------------------------------------
-- 6. amenities — sixth; references nothing.
-- ----------------------------------------------------------------
CREATE TABLE amenities (
    amenity_id    INTEGER GENERATED ALWAYS AS IDENTITY,
    display_name  VARCHAR(100) NOT NULL,
    CONSTRAINT pk_amenities PRIMARY KEY (amenity_id),
    CONSTRAINT uq_amenities_display_name UNIQUE (display_name)
);

-- ----------------------------------------------------------------
-- 7. viewings — seventh; references renters and properties.
-- ----------------------------------------------------------------
CREATE TABLE viewings (
    viewing_id    INTEGER    GENERATED ALWAYS AS IDENTITY,
    renter_id     INTEGER    NOT NULL,
    property_id   INTEGER    NOT NULL,
    viewed_at     TIMESTAMP  NOT NULL,
    duration_min  INTEGER    NOT NULL,
    CONSTRAINT pk_viewings PRIMARY KEY (viewing_id),
    CONSTRAINT fk_viewings_renter
        FOREIGN KEY (renter_id) REFERENCES renters (account_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_viewings_property
        FOREIGN KEY (property_id) REFERENCES properties (property_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_viewings_duration_positive CHECK (duration_min > 0),
    CONSTRAINT chk_viewings_not_future CHECK (viewed_at <= CURRENT_TIMESTAMP)
);

-- ----------------------------------------------------------------
-- 8. listing_amenities — eighth; resolves the M:N between
--    properties and amenities. 
--    The primary key is the pair of foreign keys,
--    not a new id.
-- ----------------------------------------------------------------
CREATE TABLE listing_amenities (
    property_id  INTEGER  NOT NULL,
    amenity_id   INTEGER  NOT NULL,
    CONSTRAINT pk_listing_amenities PRIMARY KEY (property_id, amenity_id),
    CONSTRAINT fk_listing_amenities_property
        FOREIGN KEY (property_id) REFERENCES properties (property_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_listing_amenities_amenity
        FOREIGN KEY (amenity_id) REFERENCES amenities (amenity_id)
        ON DELETE CASCADE
);

-- ----------------------------------------------------------------
-- 9. reviews — last; references viewings.
-- ----------------------------------------------------------------
CREATE TABLE reviews (
    review_id    INTEGER        GENERATED ALWAYS AS IDENTITY,
    viewing_id   INTEGER        NOT NULL,
    rating       NUMERIC(3,2)   NOT NULL,
    comment      TEXT,
    created_at   TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),
    CONSTRAINT uq_reviews_viewing UNIQUE (viewing_id),
    CONSTRAINT fk_reviews_viewing
        FOREIGN KEY (viewing_id) REFERENCES viewings (viewing_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_reviews_rating_range CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT chk_reviews_low_rating_requires_comment
        CHECK (rating >= 3 OR comment IS NOT NULL)
);
