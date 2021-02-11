import { Controller } from 'stimulus'

export default class extends Controller {
  static targets = [ 'canvas', 'webcam', 'patient', 'confirm', 'abort', 'pin', 'box', 'boxWarning', 'last' ]

  initialize() {
    this.boundKeyDownConfirm = this.keyDownConfirm.bind(this);
    this.boundKeyDownAbort = this.keyDownAbort.bind(this);
  }

  connect() {
    var context = this.canvasTarget.getContext("2d")
    // rotate canvas
    context.translate(640, 480);
    context.scale(-1, -1);
    this.boxTarget.focus()
    this.startWebcam()
  }

  startWebcam() {
    var video = this.webcamTarget
    if(navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        navigator.mediaDevices.getUserMedia({ video: true }).then(function(stream) {
          video.srcObject = stream
          video.play()
        });
    }
    this.snap()
  }

  snap() {
    if (this.boxTarget.value != "") {
      this.boxWarningTarget.style.display = "none"
      var context = this.canvasTarget.getContext("2d")
      context.drawImage(this.webcamTarget, 0, 0, 640, 480)
      var dataURL = this.canvasTarget.toDataURL("image/jpeg")
      var request = this.createRequest("POST", "cards/snap", true)
      request.onload = () => {
        this.responseProcessing(JSON.parse(request.response))
      }
      var ready = false
      if (this.pinTarget.value == '') {
        ready = true
      }
      request.send(`ready=${ready}&box=${this.boxTarget.value}&img=${dataURL}`)
    } else {
      this.boxWarningTarget.style.display = "block"
      setTimeout(() => this.snap(), 1000)
    }
    this.last()
  }

  responseProcessing(response) {
    if (response == null) {
      setTimeout(() => this.snap(), 1250)
    } else {
      if (response.next != null) {
        this.waitingNextCard()
      } else {
        this.patient(response)
      }
    }
  }

  patient(patient) {
    this.pinTarget.value = patient.pin
    this.patientTarget.innerHTML = patient.surname + "<br>"
                                 + patient.name1 + "<br>"
                                 + patient.name2 + "<p>"
                                 + patient.dr + "<p>"
                                 + patient.pin
    if (patient.checked) {
      this.patientTarget.parentNode.style["background-color"] = "#ccffcc"
      this.abortTarget.style.display = "block"
      this.last()
      document.addEventListener("keydown", this.boundKeyDownAbort)
      this.snap()
    } else {
      this.patientTarget.parentNode.style["background-color"] = "#ff8080"
      this.confirmTarget.style.display = "block"
      document.addEventListener("keydown", this.boundKeyDownConfirm)
    }
  }

  waitingNextCard() {
    this.clearPatient()
    this.patientTarget.innerHTML = "Ожидание следующей карты..."
    this.pinTarget.value = ""
    this.snap()
  }

  confirm() {
    document.removeEventListener("keydown", this.boundKeyDownConfirm)
    var request = this.createRequest("POST", "cards/confirm", true)
    request.send(`box=${this.boxTarget.value}&pin=${this.pinTarget.value}`)
    this.clearPatient()
    this.snap()
  }

  reject() {
    document.removeEventListener("keydown", this.boundKeyDownConfirm)
    this.pinTarget.value = ""
    this.waitingNextCard()
  }

  abort() {
    document.removeEventListener("keydown", this.boundKeyDownAbort)
    var request = this.createRequest("POST", "cards/remove_patient", true)
    request.send(`box=${this.boxTarget.value}&pin=${this.pinTarget.value}`)
    this.clearPatient()
    this.pinTarget.value = ""
    this.patientTarget.innerHTML = "Ожидание следующей карты..."
  }

  createRequest(http_method, url, async) {
    var request = new XMLHttpRequest()
    request.open(http_method, url, async)
    request.setRequestHeader('Content-type', 'application/x-www-form-urlencoded')
    return request
  }

  clearPatient() {
    this.patientTarget.parentNode.style["background-color"] = "white"
    this.confirmTarget.style.display = "none"
    this.abortTarget.style.display = "none"
    this.patientTarget.innerHTML = ""
  }

  keyDownConfirm(event) {
    if (event.key == " ") {
      this.confirm()
    }
    if (event.key == "Escape") {
      this.reject()
    }
  }

  keyDownAbort(event) {
    if (event.key == "Escape") {
      this.abort()
    }
  }

  last() {
    var request = this.createRequest("GET", "cards/last", true)
    request.onload = () => {
      this.tableLast(JSON.parse(request.response))
    }
    request.send()
  }

  tableLast(response) {
    var lastContent = "<tbody>"
    response.forEach((patient) => {
      lastContent += "<tr>"
      lastContent += `<td>${patient.pin}</td>`
      lastContent += `<td>${patient.name}</td>`
      lastContent += `<td>${patient.dr}</td>`
      lastContent += `<td>${patient.box}</td>`
      lastContent += "</tr>"
    })
    lastContent += "</tbody>"
    this.lastTarget.innerHTML = lastContent
  }
}
