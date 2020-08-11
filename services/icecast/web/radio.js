
const cajonURL = "https://cajon.nidi.to/ruiditos"

function toggleLive() {
  window.fetch("/status.json").then( response => {
    data = response.json()

    if (! data.source) {
      console.log("apagado")
      document.querySelector("#apagado").style.display = ""
      document.querySelector("#al-aire").style.display = "none"
      setTimeout(fetchRecordings, 10000)
      return
    }

    document.querySelector("#apagado").style.display = "none"
    document.querySelector("#al-aire").style.display = ""

    let titulo = data.source.title || data.source.yp_currently_playing || data.source.server_description
    document.querySelector("#titulo").innerText = titulo
    let empezo = data.source.stream_start

    // 10/Aug/2020:23:03:12 +0000
    let expr = /(?<date>[^:]+):(?<time>[^ ]+) (?<tz>.+)/
    let {date, time, tz} = empezo.match(expr).groups
    let [day, monthName, year] = date.split("/")
    let trueDate = Date.parse(`${monthName} ${day}, ${year} ${time} ${tz}`)

    document.querySelector("#fecha").innerText = trueDate.toLocaleDateString() + " @ " + trueDate.toLocaleTimeString()
  })
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
      .map(c => {
        let filename = c.innerHTML
        let [date, time] = filename.split(".")[0].split('T');
        let parseableDate = `${date}T${time.replace(/-/g,":")}.000+00:00`
        let instant = new Date(Date.parse(parseableDate))
        return `<li>
          <h3>${instant.toLocaleDateString()} @ ${instant.toLocaleTimeString()}</h3>
          <audio controls="controls" preload="metadata">
              <source src="${cajonURL}/${filename}" type="audio/mpeg"></source>
          </audio>
        </li>`
      })
      .join("")

      console.log(data)
      document.querySelector("#anteriormente").innerHTML = data
    }).catch(err => {
      console.error(err)
      let anteriormente = document.querySelector("#anteriormente")
      anteriormente.innerHTML = '<p>Quién sabe, algo falló cuando buscaba las transmisiones</p>'
    })
}

toggleLive()
fetchRecordings()
