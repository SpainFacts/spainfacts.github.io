SELECT * FROM electricidad_5min WHERE ts_utc >= (SELECT max(ts_utc) FROM electricidad_5min) - INTERVAL 24 HOUR
