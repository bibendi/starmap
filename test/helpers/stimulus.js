import { Application } from '@hotwired/stimulus'

export async function waitForStimulus() {
  await new Promise((resolve) => setTimeout(resolve, 0))
  await new Promise((resolve) => requestAnimationFrame(resolve))
}

export async function renderController(controllerClass, options = {}) {
  const { html = '', controllerName = 'test', dataset = {} } = options

  const application = Application.start()
  application.register(controllerName, controllerClass)

  const container = document.createElement('div')
  container.setAttribute('data-controller', controllerName)

  Object.entries(dataset).forEach(([key, value]) => {
    container.setAttribute(`data-${controllerName}-${key}-value`, value)
  })

  container.innerHTML = html
  document.body.appendChild(container)

  await waitForStimulus()

  return {
    application,
    container,
    cleanup: () => {
      application.stop()
      container.remove()
    }
  }
}
