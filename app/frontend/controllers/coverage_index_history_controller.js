import { Chart } from 'chart.js/auto'
import DialogController from './dialog_controller'

const MAX_QUARTERS = 10
const FETCH_TIMEOUT = 10000

export default class extends DialogController {
  static values = {
    teamIds: Array,
    url: { type: String, default: '/coverage_index_history' },
    axisQuarter: { type: String, default: 'Quarter' },
    axisCoverage: { type: String, default: 'Coverage Index' }
  }

  static targets = [...super.targets, 'canvas', 'loading', 'error', 'empty', 'chartContainer']

  connect() {
    super.connect()
    this.fetching = false
    this.chart = null
    this.abortController = null
  }

  disconnect() {
    this.abortController?.abort()
    this.destroyChart()
  }

  open(event) {
    if (event.type === 'keydown' && !['Enter', ' '].includes(event.key)) return
    if (this.dialogTarget.open || this.fetching) return

    super.open(event)
    this.showLoading()
    this.fetchHistory()
  }

  close(event) {
    super.close(event)
  }

  retry() {
    this.showLoading()
    this.fetchHistory()
  }

  onDialogClose() {
    this.abortController?.abort()
    this.destroyChart()
    this.fetching = false
    super.onDialogClose()
  }

  async fetchHistory() {
    this.fetching = true
    this.abortController = new AbortController()
    const timeoutId = setTimeout(() => this.abortController.abort(), FETCH_TIMEOUT)

    try {
      const params = new URLSearchParams()
      for (const id of this.teamIdsValue) {
        params.append('team_ids[]', id)
      }

      const response = await fetch(`${this.urlValue}?${params.toString()}`, {
        headers: { Accept: 'application/json' },
        signal: this.abortController.signal
      })

      if (!response.ok) {
        this.showError()
        return
      }

      const data = await response.json()
      this.handleData(data)
    } catch {
      this.showError()
    } finally {
      clearTimeout(timeoutId)
      this.fetching = false
      this.abortController = null
    }
  }

  handleData(data) {
    const history = data.history || []

    if (history.length === 0) {
      this.showEmpty()
      return
    }

    this.showChart(history)
  }

  showChart(history) {
    const visible = history.slice(-MAX_QUARTERS)

    this.hideAll()
    this.chartContainerTarget.classList.remove('hidden')

    const ctx = this.canvasTarget.getContext('2d')
    this.destroyChart()

    this.chart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: visible.map((d) => d.quarter_name),
        datasets: [
          {
            label: 'Coverage Index',
            data: visible.map((d) => d.coverage_index),
            backgroundColor: 'rgba(99, 102, 241, 0.7)',
            borderColor: 'rgb(99, 102, 241)',
            borderWidth: 1,
            borderRadius: 4,
            maxBarThickness: 60
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (ctx) => `${ctx.parsed.y}%`
            }
          }
        },
        scales: {
          x: {
            title: { display: true, text: this.axisQuarterValue },
            grid: { display: false }
          },
          y: {
            min: 0,
            max: 100,
            title: { display: true, text: this.axisCoverageValue },
            ticks: {
              callback: (value) => `${value}%`
            }
          }
        }
      }
    })
  }

  showLoading() {
    this.hideAll()
    this.loadingTarget.classList.remove('hidden')
  }

  showError() {
    this.hideAll()
    this.errorTarget.classList.remove('hidden')
  }

  showEmpty() {
    this.hideAll()
    this.emptyTarget.classList.remove('hidden')
  }

  hideAll() {
    this.loadingTarget.classList.add('hidden')
    this.errorTarget.classList.add('hidden')
    this.emptyTarget.classList.add('hidden')
    this.chartContainerTarget.classList.add('hidden')
  }

  destroyChart() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
