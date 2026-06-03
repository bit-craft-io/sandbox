CREATE TABLE SchemaMigrations (
  Version INT64 NOT NULL,
  Dirty BOOL NOT NULL,
) PRIMARY KEY(Version);

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

CREATE UNIQUE INDEX idx_u_profile_id ON u_profile(id);

CREATE INDEX idx_u_profile_public_id ON u_profile(public_id);

CREATE TABLE h_access (
  id STRING(36) NOT NULL,
  public_id STRING(12) NOT NULL,
  info JSON,
) PRIMARY KEY(id);

CREATE UNIQUE INDEX idx_h_access_id ON h_access(id);

CREATE INDEX idx_h_access_public_id ON h_access(public_id);
