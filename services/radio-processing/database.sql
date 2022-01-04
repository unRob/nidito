CREATE TABLE tracks(
  timestamp text primary key,
  title varchar(10),
  album varchar(255),
  artist varchar(255),
  genre varchar(255),
  timezone varchar(100),
  path text,
  channels int,
  duration float,
  bit_rate int,
  processing_hash varchar(255),
  track_hash varchar(255)
)
