
const cajonURL = "https://cajon.nidi.to/ruiditos"

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

function renderPlayer(filename, wrapper="div") {
  let [date, time, kind, name, ext] = filename.split(".");
  if (ext != "mp3") {
    return ""
  }
  let parseableDate = `${date}T${time.replace(/-/g,":")}.000+00:00`
  let instant = new Date(Date.parse(parseableDate))
  kind = kind[0].toLocaleUpperCase() + kind.slice(1)
  name = name.split("-").join(" ")

  let dateHTML = `<code>${instant.toLocaleDateString()} @ ${instant.toLocaleTimeString()}</code>`
  if (wrapper == "li") {
    dateHTML = `<a href="/play.html?track=${filename}">${dateHTML}</a>`
  }

  return `<${wrapper}>
    <h3>${dateHTML} ${kind}: ${name}</h3>
    <audio controls="controls" preload="metadata" style="width:100%">
        <source src="${cajonURL}/${filename}" type="audio/mpeg"></source>
    </audio>
  </${wrapper}>`
}

function fetchRecordings() {
  window.fetch(`${cajonURL}/`)
    .then(response => response.text())
    .then(str => (new window.DOMParser()).parseFromString(str, "text/xml"))
    .then(xml => {
      let keys = xml.querySelectorAll("Contents Key")
      xml.querySelectorAll("Contents Key")
      let data = Array.prototype.slice.call(keys, Math.max(keys.length - 10, 0))
        .reverse()
        .map(c => renderPlayer(c.innerHTML, "li"))
        .join("")

      document.querySelector("#anteriormente").innerHTML = data
    }).catch(err => {
      console.error(err)
      let anteriormente = document.querySelector("#anteriormente")
      anteriormente.innerHTML = '<p>Quién sabe, algo falló cuando buscaba las transmisiones</p>'
    })
}

if (window.location.pathname == "/") {
  toggleLive()
  fetchRecordings()
} else if (window.location.pathname == "/play.html" ) {
  let {track} = window.location.search.substr(1).split("&").reduce((col, qp) => {
      let [k, v] = qp.split("=")
      col[k] = v
      return col
  }, {})
  document.querySelector("#track").innerHTML = renderPlayer(track)
}
