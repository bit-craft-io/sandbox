CREATE TABLE h_access
(
    id        STRING(36) NOT NULL,
    public_id STRING(12) NOT NULL,
    info      JSON
) PRIMARY KEY(id);

CREATE UNIQUE INDEX idx_h_access_id ON h_access (id);
CREATE INDEX idx_h_access_public_id ON h_access (public_id);
