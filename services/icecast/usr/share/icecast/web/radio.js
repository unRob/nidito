
const cajonURL = "https://cajon.nidi.to/ruiditos"
const tzs = {'America/New_York': "Bruclin, Nuevayorc", 'America/Mexico_City': 'México, Distrito Federal'}

function toggleLive() {
  window.fetch("/status.json")
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
    radioURL.host = window.location.host
    radioURL.protocol = window.location.protocol
    radioURL.port = window.location.port
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

function renderPlayer(track, wrapper="div") {
  let instant = new Date(Date.parse(track.timestamp))

  let title = `${track.title}`
  if (wrapper == "li") {
    title = `<a href="/play.html?track=${track.path}">${title}</a>`
  }

  return `<${wrapper} style="background-image: url(${cajonURL}/processed/${track.path.replace(/\.mp3$/, '.png')}); background-size: cover;background-position: center center;background-repeat: no-repeat;">
    <h3><code>${track.genre}/${track.album}</code> ${title}</h3>
    <audio controls="controls" preload="metadata" style="width:100%;">
        <source src="${cajonURL}/${track.path}" type="audio/mpeg"></source>
    </audio>
  </${wrapper}>`
}

function renderError(err, message="Quién sabe, algo falló cuando buscaba las transmisiones") {
  console.error(err)
  let anteriormente = document.querySelector("#anteriormente")
  anteriormente.innerHTML = `<p>${message}</p>`
}

function fetchRecordings() {
  window.fetch(`${cajonURL}/tracks.json`)
    .then(response => response.json())
    .then(tracks => {
      let data = tracks.slice(0,15)
        .map(track => renderPlayer(track, "li"))
        .join("")

      document.querySelector("#anteriormente").innerHTML = data
    }).catch(err => {
      renderError(err)
    })
}

if (window.location.pathname == "/") {
  toggleLive()
  fetchRecordings()
} else if (window.location.pathname == "/play.html" ) {
  let {track: trackPath} = window.location.search.substr(1).split("&").reduce((col, qp) => {
      let [k, v] = qp.split("=")
      col[k] = decodeURI(v)
      return col
  }, {})

  window.fetch(`${cajonURL}/tracks.json`)
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
