import { test, expect } from '@playwright/test'

test.describe('{{ENTITY}} CRUD', () => {
  test('should display {{ENTITY_PLURAL_LOWER}} list page', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await expect(page.locator('h1')).toContainText('{{LIST_TITLE}}')
  })

  test('should create a new {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.click('{{CREATE_BUTTON_SELECTOR}}')
    await expect(page).toHaveURL(/{{CREATE_URL_PATTERN}}/)

{{FILL_FORM_FIELDS}}

    await page.click('button[type="submit"]')
    await expect(page).toHaveURL(/{{LIST_URL_PATTERN}}/)
    await expect(page.locator('{{LIST_ITEM_SELECTOR}}')).toContainText({{EXPECTED_VALUE}})
  })

  test('should read {{ENTITY_LOWER}} details', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.click('{{FIRST_ITEM_SELECTOR}}')
    await expect(page).toHaveURL(/{{DETAIL_URL_PATTERN}}/)
{{DETAIL_ASSERTIONS}}
  })

  test('should update an existing {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.click('{{FIRST_ITEM_SELECTOR}}')
    await page.click('{{EDIT_BUTTON_SELECTOR}}')
    await expect(page).toHaveURL(/{{EDIT_URL_PATTERN}}/)

{{UPDATE_FORM_FIELDS}}

    await page.click('button[type="submit"]')
    await expect(page).toHaveURL(/{{LIST_URL_PATTERN}}/)
    await expect(page.locator('{{LIST_ITEM_SELECTOR}}')).toContainText({{UPDATED_VALUE}})
  })

  test('should delete a {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    const countBefore = await page.locator('{{LIST_ITEM_SELECTOR}}').count()

    await page.click('{{DELETE_BUTTON_SELECTOR}}')
    await page.click('{{CONFIRM_DELETE_SELECTOR}}')

    await expect(page.locator('{{LIST_ITEM_SELECTOR}}')).toHaveCount(countBefore - 1)
  })
})
