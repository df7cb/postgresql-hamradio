-- call

CREATE DOMAIN call AS text
    CONSTRAINT valid_callsign CHECK (VALUE ~ '^[A-Z0-9]+([/-][A-Z0-9]+)*$'::text);

-- band

CREATE TYPE band AS ENUM (
    '2190m', '630m', '560m',
    '160m', '80m', '60m', '40m', '30m', '20m', '17m', '15m', '12m', '10m',
    '6m', '4m', '2m', '1.25m',
    '70cm', '33cm', '23cm', '13cm', '9cm', '6cm', '3cm', '1.25cm',
    '6mm', '4mm', '2.5mm', '2mm', '1mm');

CREATE OR REPLACE FUNCTION band(qrg numeric) RETURNS band
    LANGUAGE SQL AS
$$SELECT CASE
    WHEN qrg BETWEEN 0.136 AND 0.137       THEN '2190m'::band
    WHEN qrg BETWEEN 0.472 AND 0.479       THEN '630m'
    WHEN qrg BETWEEN 0.501 AND 0.504       THEN '560m'
    WHEN qrg BETWEEN 1.8 AND 2.0           THEN '160m'
    WHEN qrg BETWEEN 3.5 AND 4.0           THEN '80m'
    WHEN qrg BETWEEN 5.102 AND 5.4065      THEN '60m'
    WHEN qrg BETWEEN 7.0 AND 7.3           THEN '40m'
    WHEN qrg BETWEEN 10.0 AND 10.15        THEN '30m'
    WHEN qrg BETWEEN 14.0 AND 14.35        THEN '20m'
    WHEN qrg BETWEEN 18.0 AND 18.168       THEN '17m'
    WHEN qrg BETWEEN 21.0 AND 21.45        THEN '15m'
    WHEN qrg BETWEEN 24.89 AND 24.99       THEN '12m'
    WHEN qrg BETWEEN 28.0 AND 29.7         THEN '10m'
    WHEN qrg BETWEEN 50.0 AND 54.0         THEN '6m'
    WHEN qrg BETWEEN 70.0 AND 71.0         THEN '4m'
    WHEN qrg BETWEEN 144.0 AND 148.0       THEN '2m'
    WHEN qrg BETWEEN 222.0 AND 225.0       THEN '1.25m'
    WHEN qrg BETWEEN 420.0 AND 450.0       THEN '70cm'
    WHEN qrg BETWEEN 902.0 AND 928.0       THEN '33cm'
    WHEN qrg BETWEEN 1240.0 AND 1300.0     THEN '23cm'
    WHEN qrg BETWEEN 2300.0 AND 2450.0     THEN '13cm'
    WHEN qrg BETWEEN 3300.0 AND 3500.0     THEN '9cm'
    WHEN qrg BETWEEN 5650.0 AND 5925.0     THEN '6cm'
    WHEN qrg BETWEEN 10000.0 AND 10500.0   THEN '3cm'
    WHEN qrg BETWEEN 24000.0 AND 24250.0   THEN '1.25cm'
    WHEN qrg BETWEEN 47000.0 AND 47200.0   THEN '6mm'
    WHEN qrg BETWEEN 75500.0 AND 81000.0   THEN '4mm'
    WHEN qrg BETWEEN 119980.0 AND 120020.0 THEN '2.5mm'
    WHEN qrg BETWEEN 142000.0 AND 149000.0 THEN '2mm'
    WHEN qrg BETWEEN 241000.0 AND 250000.0 THEN '1mm'
END$$;

CREATE CAST (numeric AS band) WITH FUNCTION band AS ASSIGNMENT;

-- locator

CREATE DOMAIN locator AS text
    CONSTRAINT valid_locator CHECK (VALUE ~ '^[A-R][A-R](?:[0-9][0-9](?:[A-Xa-x][A-Xa-x](?:[0-9][0-9](?:[A-Xa-x][A-Xa-x])?)?)?)?$');

CREATE OR REPLACE FUNCTION locator_as_linestring (loc locator) RETURNS text
STRICT LANGUAGE plpgsql
AS $$DECLARE
    a1 int := ascii(substr(loc, 1, 1)) - 65; -- field
    a2 int := ascii(substr(loc, 2, 1)) - 65;
    b1 int := ascii(substr(loc, 3, 1)) - 48; -- square
    b2 int := ascii(substr(loc, 4, 1)) - 48;
    c1 int := ascii(upper(substr(loc, 5, 1))) - 65; -- subsquare
    c2 int := ascii(upper(substr(loc, 6, 1))) - 65;
    d1 int := ascii(substr(loc, 7, 1)) - 48;
    d2 int := ascii(substr(loc, 8, 1)) - 48;
    e1 int := ascii(upper(substr(loc, 9, 1))) - 65;
    e2 int := ascii(upper(substr(loc, 10, 1))) - 65;
    lon_d double precision := 20;
    lat_d double precision := 10;
    lon double precision;
    lat double precision;
BEGIN
    lon := -180 + lon_d * a1;
    lat := -90 + lat_d * a2;
    IF b1 >= 0 THEN
        lon_d = 2;
        lat_d = 1;
        lon := lon + lon_d * b1;
        lat := lat + lat_d * b2;
        IF c1 >= 0 THEN
            lon_d = 2.0/24;
            lat_d = 1.0/24;
            lon := lon + lon_d * c1;
            lat := lat + lat_d * c2;
            IF d1 >= 0 THEN
                lon_d = .2/24;
                lat_d = .1/24;
                lon := lon + lon_d * d1;
                lat := lat + lat_d * d2;
                IF e1 >= 0 THEN
                    lon_d = .2/24/24;
                    lat_d = .1/24/24;
                    lon := lon + lon_d * e1;
                    lat := lat + lat_d * e2;
                END IF;
            END IF;
        END IF;
    END IF;
RETURN format('LINESTRING(%s %s,%s %s,%s %s,%s %s,%s %s)',
    lon, lat,
    lon + lon_d, lat,
    lon + lon_d, lat + lat_d,
    lon, lat + lat_d,
    lon, lat);
END$$;

CREATE OR REPLACE FUNCTION ST_Locator(loc locator) RETURNS geometry(POLYGON, 4326)
STRICT LANGUAGE SQL
AS $$SELECT ST_Polygon(ST_GeomFromText(locator_as_linestring(loc)), 4326)$$;

CREATE OR REPLACE FUNCTION locator_as_point (loc locator) RETURNS text
STRICT LANGUAGE plpgsql
AS $$DECLARE
    a1 int := ascii(substr(loc, 1, 1)) - 65; -- field
    a2 int := ascii(substr(loc, 2, 1)) - 65;
    b1 int := ascii(substr(loc, 3, 1)) - 48; -- square
    b2 int := ascii(substr(loc, 4, 1)) - 48;
    c1 int := ascii(upper(substr(loc, 5, 1))) - 65; -- subsquare
    c2 int := ascii(upper(substr(loc, 6, 1))) - 65;
    d1 int := ascii(substr(loc, 7, 1)) - 48;
    d2 int := ascii(substr(loc, 8, 1)) - 48;
    e1 int := ascii(upper(substr(loc, 9, 1))) - 65;
    e2 int := ascii(upper(substr(loc, 10, 1))) - 65;
    lon_d double precision := 20;
    lat_d double precision := 10;
    lon double precision;
    lat double precision;
BEGIN
    lon := -180 + lon_d * a1;
    lat := -90 + lat_d * a2;
    IF b1 >= 0 THEN
        lon_d = 2;
        lat_d = 1;
        lon := lon + lon_d * b1;
        lat := lat + lat_d * b2;
        IF c1 >= 0 THEN
            lon_d = 2.0/24;
            lat_d = 1.0/24;
            lon := lon + lon_d * c1;
            lat := lat + lat_d * c2;
            IF d1 >= 0 THEN
                lon_d = .2/24;
                lat_d = .1/24;
                lon := lon + lon_d * d1;
                lat := lat + lat_d * d2;
                IF e1 >= 0 THEN
                    lon_d = .2/24/24;
                    lat_d = .1/24/24;
                    lon := lon + lon_d * e1;
                    lat := lat + lat_d * e2;
                END IF;
            END IF;
        END IF;
    END IF;
RETURN format('POINT(%s %s)',
    lon + lon_d/2, lat + lat_d/2);
END$$;

CREATE OR REPLACE FUNCTION ST_LocatorPoint(loc locator) RETURNS geometry(POINT, 4326)
STRICT LANGUAGE SQL
AS $$SELECT ST_PointFromText(locator_as_point(loc), 4326)$$;

-- generate locators

CREATE TABLE locator2 (
  field varchar(2) PRIMARY KEY,
  geom geometry(POLYGON, 4326) NOT NULL
);
INSERT INTO locator2
  SELECT chr(lon)||chr(lat), ST_Locator(chr(lon)||chr(lat))
  FROM generate_series(65, 82) lon, generate_series(65, 82) lat;
CREATE INDEX ON locator2 USING gist(geom);

CREATE TABLE locator4 (
  field varchar(4) PRIMARY KEY,
  geom geometry(POLYGON, 4326) NOT NULL
);
INSERT INTO locator4
  SELECT chr(lon)||chr(lat)||chr(lon2)||chr(lat2), ST_Locator(chr(lon)||chr(lat)||chr(lon2)||chr(lat2))
  FROM generate_series(65, 82) lon, generate_series(65, 82) lat,
       generate_series(48, 57) lon2, generate_series(48, 57) lat2;
CREATE INDEX ON locator4 USING gist(geom);

