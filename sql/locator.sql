SELECT 'JO'::locator;
SELECT 'JO31'::locator;
SELECT 'JO31hi'::locator;
SELECT 'JO31HI'::locator;
SELECT 'JO31hi19'::locator;
SELECT 'JO31hi19lj'::locator;
SELECT ST_Locator('JO');
SELECT ST_Locator('JO31');
SELECT ST_Locator('JO31hi');
SELECT ST_Locator('JO31hi19');
SELECT ST_Locator('JO31hi19lj');
SELECT ST_LocatorPoint('JO');
SELECT ST_LocatorPoint('JO31');
SELECT ST_LocatorPoint('JO31hi');
SELECT ST_LocatorPoint('JO31hi19');
SELECT ST_LocatorPoint('JO31hi19lj');
SELECT field FROM locator2 WHERE ST_Intersects(geom, ST_SetSRID(ST_Point(6.629, 51.356), 4326));
SELECT field FROM locator4 WHERE ST_Intersects(geom, ST_SetSRID(ST_Point(6.629, 51.356), 4326));

-- errors
SELECT 'J'::locator;
SELECT 'JO3'::locator;
SELECT 'jo31'::locator;
