import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { use{{ENTITY}}Store } from '{{STORE_IMPORT_PATH}}'

vi.mock('{{SERVICE_IMPORT_PATH}}', () => ({
  {{ENTITY_CAMEL}}Service: {
    list: vi.fn(),
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

describe('use{{ENTITY}}Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('has initial state', () => {
    const store = use{{ENTITY}}Store()
    expect(store.items).toEqual([])
    expect(store.current).toBeNull()
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
  })

  {{ADDITIONAL_TESTS}}
})
