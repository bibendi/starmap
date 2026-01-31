export function getByTestId(testId) {
  const element = document.querySelector(`[data-testid="${testId}"]`)
  if (!element) {
    throw new Error(`Element with data-testid="${testId}" not found`)
  }
  return element
}

export function queryByTestId(testId) {
  return document.querySelector(`[data-testid="${testId}"]`) || null
}

export function getAllByTestId(testId) {
  return Array.from(document.querySelectorAll(`[data-testid="${testId}"]`))
}

export function userEvent() {
  return {
    async click(element) {
      if (!element) throw new Error('Element not found for click')
      element.click()
      await new Promise(resolve => setTimeout(resolve, 0))
    },
    
    async keyboard(key) {
      const event = new KeyboardEvent('keydown', { key })
      document.activeElement?.dispatchEvent(event)
      await new Promise(resolve => setTimeout(resolve, 0))
    }
  }
}
