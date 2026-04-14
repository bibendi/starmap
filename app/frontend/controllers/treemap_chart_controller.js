import { Controller } from '@hotwired/stimulus'
import { Chart } from 'chart.js/auto'
import { TreemapController, TreemapElement } from 'chartjs-chart-treemap'

Chart.register(TreemapController, TreemapElement)

export default class extends Controller {
  static values = {
    data: Array
  }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    const getContext = this.element.getContext?.bind(this.element)
    if (!getContext) return

    const ctx = getContext('2d')
    if (!ctx) return

    const rawData = this.dataValue

    this.techDataMap = new Map()
    rawData.forEach((tech) => {
      this.techDataMap.set(tech.name, tech)
    })

    this.chart = new Chart(ctx, {
      type: 'treemap',
      data: {
        datasets: [
          {
            tree: rawData,
            key: 'value',
            groups: ['name'],
            spacing: 1,
            borderWidth: 1,
            borderColor: 'rgba(255, 255, 255, 0.3)',
            backgroundColor: (ctx) => {
              if (ctx.type !== 'data') {
                return 'transparent'
              }

              const item = ctx.raw
              if (!item) return '#cccccc'

              const name = item.g
              const techData = this.techDataMap.get(name)

              if (!techData) return '#cccccc'

              const isGood = techData.allTeamsInTarget
              const intensity = isGood ? techData.intensity : techData.deficitIntensity

              return this.getColor(isGood, intensity)
            },
            labels: {
              display: true,
              align: 'center',
              position: 'middle',
              color: ['white', 'rgba(255,255,255,0.8)', 'rgba(255,255,255,0.9)'],
              font: [{ size: 12, weight: 'bold' }, { size: 9 }, { size: 10, weight: '600' }],
              overflow: 'fit',
              formatter: (ctx) => {
                if (ctx.type !== 'data') return ''

                const item = ctx.raw
                if (!item) return ''

                const name = item.g
                const techData = this.techDataMap.get(name)

                if (!techData) return name

                return [techData.name, techData.category, `${techData.value}`]
              }
            }
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              title: (items) => {
                const item = items[0]?.raw
                if (!item) return ''
                const name = item.g
                const techData = this.techDataMap.get(name)
                return techData?.name || name
              },
              label: (context) => {
                const item = context.raw
                if (!item) return ''

                const name = item.g
                const techData = this.techDataMap.get(name)

                if (!techData) return ''

                return [
                  `Category: ${techData.category}`,
                  `Experts: ${techData.value}`,
                  `Status: ${techData.allTeamsInTarget ? 'On Target' : 'Below Target'}`
                ]
              }
            }
          }
        }
      }
    })
  }

  getColor(isGood, intensity) {
    const goodColors = ['#86efac', '#4ade80', '#22c55e', '#16a34a', '#15803d']

    const criticalColors = ['#fca5a5', '#f87171', '#ef4444', '#dc2626', '#b91c1c']

    const colors = isGood ? goodColors : criticalColors
    const index = Math.min(Math.max(intensity - 1, 0), 4)

    return colors[index]
  }
}
