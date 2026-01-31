import { afterEach, vi } from 'vitest'

afterEach(() => {
  vi.clearAllMocks()
  document.head.innerHTML = ''
  document.body.innerHTML = ''
  document.documentElement.className = ''
})
