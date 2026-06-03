CREATE TABLE h_access (
  id STRING(36) NOT NULL,
  public_id STRING(12) NOT NULL,
  info JSON,
) PRIMARY KEY(id);