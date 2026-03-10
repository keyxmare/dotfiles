import { test, expect } from '@playwright/test'

test.describe('{{ENTITY}} CRUD', () => {
  test('should display {{ENTITY_PLURAL_LOWER}} list page', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await expect(page.getByTestId('page-title')).toContainText('{{LIST_TITLE}}')
    await expect(page.getByTestId('list-table').or(page.getByTestId('empty-state'))).toBeVisible()
  })

  test('should create a new {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.getByTestId('create-btn').click()
    await expect(page).toHaveURL(/{{CREATE_URL_PATTERN}}/)

{{FILL_FORM_FIELDS}}

    await page.getByTestId('submit-btn').click()
    await expect(page).toHaveURL(/{{LIST_URL_PATTERN}}/)
    await expect(page.getByTestId('list-item')).toContainText({{EXPECTED_VALUE}})
  })

  test('should read {{ENTITY_LOWER}} details', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.getByTestId('view-btn').first().click()
    await expect(page.getByTestId('entity-detail')).toBeVisible()
{{DETAIL_ASSERTIONS}}
  })

  test('should update an existing {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    await page.getByTestId('edit-btn').first().click()
    await expect(page).toHaveURL(/{{EDIT_URL_PATTERN}}/)

{{UPDATE_FORM_FIELDS}}

    await page.getByTestId('submit-btn').click()
    await expect(page).toHaveURL(/{{LIST_URL_PATTERN}}/)
    await expect(page.getByTestId('list-item').first()).toContainText({{UPDATED_VALUE}})
  })

  test('should delete a {{ENTITY_LOWER}}', async ({ page }) => {
    await page.goto('{{LIST_URL}}')
    const countBefore = await page.getByTestId('list-item').count()

    await page.getByTestId('delete-btn').first().click()
    await expect(page.getByTestId('delete-modal')).toBeVisible()
    await page.getByTestId('confirm-delete-btn').click()

    await expect(page.getByTestId('list-item')).toHaveCount(countBefore - 1)
  })
})
