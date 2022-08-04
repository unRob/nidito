
const CDN = "https://cdn.rob.mx/ruiditos"
const SOURCE = "https://radio.nidi.to"
const tzs = {'America/New_York': "Bruclin, Nuevayorc", 'America/Mexico_City': 'México, Distrito Federal'}
const tracksPerPage = 15
let Tracks = []
let View = {page: 0, filter: null}

function getView () {
  if (window.location.search != "") {
    let params = new URLSearchParams(window.location.search)
    View.page = parseInt(params.get("page") || "1", 10) - 1

    if (params.has("genre")) {
      const genre = params.get("genre")
      document.querySelector("#genre-select").value = genre
      View.filter = TrackFilters["genre"](genre)
    }
  }
}

function duration(secs) {
  let hours = Math.floor(secs / 3600)
  let minutes = Math.floor((secs - (hours * 3600)) / 60)
  let seconds = Math.round(secs - (hours * 3600) - (minutes * 60))

  let components = [minutes, seconds]
  if (hours > 0) {
    components.unshift(hours)
  }

  return components.map(c => c < 10 ? `0${c}` : `${c}` ).join(":")
}

function toggleLive() {
  window.fetch(`${SOURCE}/status.json`)
    .then( r => r.json() )
    .then( ({ icestats }) => {

    if (!icestats.hasOwnProperty("source")) {
      document.querySelector("#apagado").style.display = ""
      document.querySelector("#al-aire").style.display = "none"
      document.querySelector("#al-aire audio").pause()
      setTimeout(toggleLive, 60000)
      return
    }
    const src = icestats.source

    document.querySelector("#apagado").style.display = "none"
    document.querySelector("#al-aire").style.display = ""

    let titulo = src.title || src.yp_currently_playing || src.server_description
    document.querySelector("#titulo").innerText = titulo
    let empezo = src.stream_start

    // 10/Aug/2020:23:03:12 +0000
    let expr = /(?<date>[^:]+):(?<time>[^ ]+) (?<tz>.+)/
    let {date, time, tz} = empezo.match(expr).groups
    let [day, monthName, year] = date.split("/")
    let trueDate = new Date(Date.parse(`${monthName} ${day}, ${year} ${time} ${tz}`))

    document.querySelector("#fecha").innerText = trueDate.toLocaleDateString() + " @ " + trueDate.toLocaleTimeString()

    let radioURL = new URL(src.listenurl)
    // radioURL.host = window.location.host
    // radioURL.protocol = window.location.protocol
    // radioURL.port = window.location.port
    let currentSrc = document.querySelector("#al-aire audio source")
    if (currentSrc.src != radioURL) {
      console.log("going live")
      document.querySelector("#al-aire audio source").src = radioURL
      let audio = document.querySelector("#al-aire audio")
      audio.outerHTML = audio.outerHTML
    }
    setTimeout(toggleLive, 15000)
  })
}

function setupPlayer(container) {
  const audio = container.querySelector("audio")
  if (container.classList.contains("setup-complete")) {
    return audio
  }

  container.classList.add("setup-complete")
  const head = container.querySelector(".track-head")
  const playtime = container.querySelector(".track-playtime")
  const playtime_remains = playtime.querySelector(".track-remaining")
  const playtime_current = playtime.querySelector(".track-current")
  audio.addEventListener("timeupdate", function() {
    head.style.width = (audio.currentTime/audio.duration*100)+"%"
    playtime_remains.innerHTML = duration(audio.duration - audio.currentTime)
    playtime_current.innerHTML = duration(audio.currentTime)
  })

  container.addEventListener("click", function(evt) {
    const target = evt.target
    if (target == container || target == head) {
      const pct = evt.layerX / container.offsetWidth
      audio.currentTime = audio.duration * pct
    } else if (target == playtime_remains || target == playtime_current || target == playtime) {
      playtime.classList.toggle("remaining")
    }
  })
  return audio
}

function togglePlayer(btn) {
  const container = btn.parentNode
  const audio = setupPlayer(container)
  const article = container.parentNode
  article.classList.toggle("playing")
  if (audio.paused) {
    audio.play()
    btn.innerHTML = "▮▮"
  } else {
    audio.pause()
    btn.innerHTML = "▶"
  }
}

function renderPlayer(track, wrapper="div") {
  let instant = new Date(Date.parse(track.timestamp))

  let title = `${track.title}`
  if (wrapper == "article") {
    title = `<a href="/play.html?track=${track.path}">${title}</a>`
  }

  return `<${wrapper} class="track-container">
    <div class="track-meta-container">
      <h3>${title}</h3>
      <div class="track-meta">
        <p>${track.genre}/${track.album}</p>
        <p class="track-artist">${track.artist}</p>
      </div>
    </div>
    <div class="track-player" style="background-image: url(${CDN}/${track.path.replace(/\.mp3$/, '.png')});">
      <button class="track-play" type="button" onclick="togglePlayer(this)">▶</button>
      <div class="track-head"></div>
      <div class="track-playtime remaining">
        <span class="track-current">00:00</span>
        <span class="track-remaining">${duration(track.duration)}<span>
      </div>
      <audio preload="none">
        <source src="${CDN}/${track.path}" type="audio/mpeg" />
      </audio>
    </div>
  </${wrapper}>`
}

function renderError(err, message="Quién sabe, algo falló cuando buscaba las transmisiones") {
  console.error(err)
  let anteriormente = document.querySelector("#anteriormente")
  anteriormente.innerHTML = `<p>${message}</p>`
}

function fetchRecordings() {
  return window.fetch(`${CDN}/tracks.json`)
    .then(response => response.json())
    .then(tracks => {
      Tracks = tracks
    }).catch(err => {
      renderError(err)
    })
}

const TrackFilters = {
  "genre": function (genre) {
    return (track) => track.genre == genre
  },
  "after": function(date) {
    return (track) => track.timestamp >= date
  }
}

function renderTracks() {
  let tracks = Tracks
  if (View.filter) {
    tracks = Tracks.filter(View.filter)
  }

  start = View.page * tracksPerPage
  end = start + tracksPerPage
  availableTracks = tracks.length
  console.log(`tracks: ${availableTracks}, start: ${start}, end: ${end}, page: ${View.page}`)

  if (availableTracks > 0) {
    let pageCount = Math.ceil(availableTracks / tracksPerPage)
    if (View.page/tracksPerPage > availableTracks) {
      throw(`Unknown page ${View.page}`)
    }

    let data = tracks.slice(start,end)
      .map(track => renderPlayer(track, "article"))
      .join("")


    document.querySelector("#anteriormente").innerHTML = data

    if (pageCount > 1) {
      document.querySelector("#page-list").innerHTML = Array.from({length: pageCount}, (_, idx) => {
        if (idx == View.page) {
          return `<li class="current-page">${idx+1}</li>`
        }

        let params = new URLSearchParams(window.location.search)
        params.set("page", `${idx+1}`)

        return `<li><a href="/?${params.toString()}#transmisiones-anteriores">${idx+1}</a></li>`
      }).join("\n")
    }
  }
}

if (window.location.pathname == "/") {
  toggleLive()
  getView()
  fetchRecordings().then(renderTracks)

  document.querySelector("#genre-select").addEventListener("change", (evt) => {
    let val = evt.target.value
    if (val == "") {
      window.location.search = ""
    } else {
      window.location.search = `?genre=${val}`
    }
  })
} else if (window.location.pathname == "/play.html" ) {
  let {track: trackPath} = window.location.search.substr(1).split("&").reduce((col, qp) => {
      let [k, v] = qp.split("=")
      col[k] = decodeURI(v)
      return col
  }, {})

  window.fetch(`${CDN}/tracks.json`)
    .then(response => response.json())
    .then(tracks => {
      let track = tracks.find(t => t.path == trackPath)

      if (!track) {
        document.querySelector("#track").innerHTML = "Esa transmisión ya no existe :("
        return
      }

      document.querySelector("#location").innerHTML = tzs[track.timezone] || "mi casa"
      document.querySelector("#track").innerHTML = renderPlayer(track)
    })
    .catch(err => {
      renderError(err)
    })

}
