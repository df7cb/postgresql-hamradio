EXTENSION = hamradio
DATA = hamradio--1.sql
REGRESS = init call band locator

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
