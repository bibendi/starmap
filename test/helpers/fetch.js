export function mockFetch(response = { ok: true, json: () => Promise.resolve({}) }) {
  global.fetch = vi.fn().mockImplementation(() =>
    Promise.resolve({
      ok: true,
      status: 200,
      json: () => Promise.resolve({}),
      text: () => Promise.resolve(''),
      ...response
    })
  )
  return global.fetch
}

export function mockFetchError(error = new Error('Network error')) {
  global.fetch = vi.fn().mockRejectedValue(error)
  return global.fetch
}

export function mockFetchSequence(responses) {
  let callIndex = 0
  global.fetch = vi.fn().mockImplementation(() => {
    const response = responses[callIndex] || { ok: true }
    callIndex++
    return Promise.resolve({
      ok: true,
      status: 200,
      json: () => Promise.resolve({}),
      ...response
    })
  })
  return global.fetch
}

export function assertFetchCalled() {
  expect(fetch).toHaveBeenCalled()
}

export function assertFetchNotCalled() {
  expect(fetch).not.toHaveBeenCalled()
}

export function clearFetchMocks() {
  if (global.fetch?.mockClear) {
    global.fetch.mockClear()
  }
}

export function createCSRFToken(token = 'test-csrf-token') {
  const meta = document.createElement('meta')
  meta.name = 'csrf-token'
  meta.content = token
  document.head.appendChild(meta)
  return meta
}
