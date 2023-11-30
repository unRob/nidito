# radio.nidi.to

Live streaming audio and recording of my home music room. Backend is [Icecast-KH](https://github.com/karlheyes/icecast-kh). Catalog and live stream available via [ruidi.to](../ruidi.to/).

## Streams

- presenta: guest performances at the Sala Nidito
- practicando: my regular practice rounds, meaning mostly Debussy's "Clair de Lune" and some other stuff here and there
- jugando: live streams of random shit, mostly to test the streaming latency or broadcast my nieces' improvisation


## Client setup

Mount points map to streams above


---

```yaml
metadata:
  id2v3:
    year: int
    track: int
    title: string
    album: Album (month year|RN presenta...|Ruiditos)
    artist: Artist
    genre: string (practicando|jugando|presenta)
  timestamp: time
  timezone: string
  channels: int
  duration: float
  bitrate: int
  path: string
```

# before

0. **icecast/on-disconnect.sh** processes recording
  0.0 uploads to object storage, triggers nomad:radio-processing
  0.1 triggers event:stream:ended `{path: "Y-m-DTH-M-S.mp3"}`
1. **radio-processing/entrypoint.sh** reads every recording and burns metadata, if changed, into `Y-m-DTH-M-S.mp3`
  1.0 generates `Y-m-DTH-M-S.png`
  1.1 adds metadata to sqlite
  1.2 renders track collection into `tracks.json`
  1.3 syncs recordings and tracks.json to CDN

# after

0. **icecast/on-connect.sh** triggers event:stream:started `{path: "Y-m-DTH-M-S.mp3"}`
1. time elapses
2. **icecast/on-disconnect.sh** processes recording
  2.0 uploads to object storage, triggers nomad:radio-processing
  2.1 triggers event:stream:ended `{path: "Y-m-DTH-M-S.mp3"}`
3. **radio-processing/entrypoint.sh** reads every recording and burns metadata, if changed, into `Y-m-DTH-M-S.mp3`
  3.0 generates `Y-m-DTH-M-S.png`
  3.1 adds metadata to sqlite
  3.2 renders track collection into `tracks.json`
  3.3 syncs recordings and tracks.json to CDN
  3.4 syncs recordings to Plex? maybe instead `rclone mount` via systemd + https://forum.rclone.org/t/synoloy-nas-does-not-support-fuse3/36944/13?u=asdffdsa
