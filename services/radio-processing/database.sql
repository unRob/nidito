CREATE TABLE tracks(
  timestamp text primary key,
  title varchar(10),
  album varchar(255),
  artist varchar(255),
  genre varchar(255),
  timezone varchar(100),
  path text,
  processing_hash varchar(255)
)
