CREATE TABLE u_profile (
  id STRING(36) NOT NULL,
  public_id STRING(12) NOT NULL,
  nick_name STRING(64),
  icon_id INT64 NOT NULL DEFAULT (1),
  energy INT64 NOT NULL DEFAULT (1),
  energy_max_regen INT64 NOT NULL DEFAULT (1),
  energy_max_stock INT64 NOT NULL DEFAULT (1),
  meta_data JSON,
) PRIMARY KEY(id);