import { afterEach, describe, expect, it } from 'vitest'
import SkillRatingLevelController from '../../app/frontend/controllers/skill_rating_level_controller.js'
import { renderController } from '../helpers/stimulus.js'
import { getByTestId, userEvent } from '../helpers/testing-library.js'

describe('SkillRatingLevelController', () => {
  let cleanup
  const user = userEvent()

  const levels = JSON.stringify({
    0: 'No knowledge',
    1: 'Basic understanding',
    2: 'Proficient',
    3: 'Can teach others'
  })

  function createRatingRowHTML() {
    return `
      <input type="radio" name="ratings[1][rating]" value="0" data-rating="0" data-action="skill-rating-level#change" data-testid="radio-0">
      <input type="radio" name="ratings[1][rating]" value="1" data-rating="1" data-action="skill-rating-level#change" data-testid="radio-1">
      <input type="radio" name="ratings[1][rating]" value="2" data-rating="2" data-action="skill-rating-level#change" data-testid="radio-2">
      <input type="radio" name="ratings[1][rating]" value="3" data-rating="3" data-action="skill-rating-level#change" data-testid="radio-3">
      <span data-skill-rating-level-target="levelText" data-testid="level-text">No knowledge</span>
    `
  }

  afterEach(() => {
    cleanup?.()
  })

  it('updates level text when rating changes', async () => {
    const result = await renderController(SkillRatingLevelController, {
      html: createRatingRowHTML(),
      controllerName: 'skill-rating-level',
      dataset: { levels }
    })
    cleanup = result.cleanup

    expect(getByTestId('level-text').textContent).toBe('No knowledge')

    await user.click(getByTestId('radio-2'))
    expect(getByTestId('level-text').textContent).toBe('Proficient')

    await user.click(getByTestId('radio-3'))
    expect(getByTestId('level-text').textContent).toBe('Can teach others')

    await user.click(getByTestId('radio-1'))
    expect(getByTestId('level-text').textContent).toBe('Basic understanding')

    await user.click(getByTestId('radio-0'))
    expect(getByTestId('level-text').textContent).toBe('No knowledge')
  })
})
