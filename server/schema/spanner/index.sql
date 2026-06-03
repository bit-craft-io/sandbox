CREATE UNIQUE INDEX idx_u_profile_id ON u_profile(id);

CREATE INDEX idx_u_profile_public_id ON u_profile(public_id);

CREATE UNIQUE INDEX idx_h_access_id ON h_access(id);

CREATE INDEX idx_h_access_public_id ON h_access(public_id);