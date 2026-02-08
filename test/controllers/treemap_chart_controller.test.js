import { afterEach, describe, expect, it, vi } from 'vitest'
import TreemapChartController from '../../app/frontend/controllers/treemap_chart_controller.js'
import { renderController } from '../helpers/stimulus.js'

describe('TreemapChartController', () => {
  let cleanup

  afterEach(() => {
    cleanup?.()
    vi.clearAllMocks()
  })

  function createCanvasHTML() {
    return '<canvas data-testid="treemap-canvas"></canvas>'
  }

  function createMockData() {
    return JSON.stringify([
      {
        name: 'Ruby',
        category: 'Backend',
        value: 5,
        allTeamsInTarget: true,
        intensity: 4,
        deficitIntensity: 1
      }
    ])
  }

  it('initializes on connect', async () => {
    const result = await renderController(TreemapChartController, {
      html: createCanvasHTML(),
      controllerName: 'treemap-chart',
      dataset: { data: createMockData() }
    })
    cleanup = result.cleanup

    expect(result.container.querySelector('canvas')).toBeTruthy()
  })

  it('cleans up on disconnect without errors', async () => {
    const result = await renderController(TreemapChartController, {
      html: createCanvasHTML(),
      controllerName: 'treemap-chart',
      dataset: { data: createMockData() }
    })
    cleanup = result.cleanup

    expect(() => cleanup()).not.toThrow()
  })

  it('generates good colors for on-target technologies', async () => {
    const result = await renderController(TreemapChartController, {
      html: createCanvasHTML(),
      controllerName: 'treemap-chart',
      dataset: { data: createMockData() }
    })
    cleanup = result.cleanup

    const controller = result.application.controllers[0]

    expect(controller.getColor(true, 1)).toBe('#86efac')
    expect(controller.getColor(true, 3)).toBe('#22c55e')
    expect(controller.getColor(true, 5)).toBe('#15803d')
  })

  it('generates red colors for below-target technologies', async () => {
    const result = await renderController(TreemapChartController, {
      html: createCanvasHTML(),
      controllerName: 'treemap-chart',
      dataset: { data: createMockData() }
    })
    cleanup = result.cleanup

    const controller = result.application.controllers[0]

    expect(controller.getColor(false, 1)).toBe('#fca5a5')
    expect(controller.getColor(false, 3)).toBe('#ef4444')
    expect(controller.getColor(false, 5)).toBe('#b91c1c')
  })

  it('clamps intensity values to valid range', async () => {
    const result = await renderController(TreemapChartController, {
      html: createCanvasHTML(),
      controllerName: 'treemap-chart',
      dataset: { data: createMockData() }
    })
    cleanup = result.cleanup

    const controller = result.application.controllers[0]

    expect(controller.getColor(true, 0)).toBe('#86efac')
    expect(controller.getColor(true, 10)).toBe('#15803d')
    expect(controller.getColor(false, -5)).toBe('#fca5a5')
  })
})
