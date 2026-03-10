import { describe, it, expect, beforeEach, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { use{{ENTITY}}Store } from '{{STORE_IMPORT_PATH}}'
import { {{ENTITY_CAMEL}}Service } from '{{SERVICE_IMPORT_PATH}}'

vi.mock('{{SERVICE_IMPORT_PATH}}', () => ({
  {{ENTITY_CAMEL}}Service: {
    list: vi.fn(),
    get: vi.fn(),
    post: vi.fn(),
    put: vi.fn(),
    delete: vi.fn(),
  },
}))

const mockedService = vi.mocked({{ENTITY_CAMEL}}Service)

describe('use{{ENTITY}}Store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial state', () => {
    const store = use{{ENTITY}}Store()
    expect(store.items).toEqual([])
    expect(store.current).toBeNull()
    expect(store.loading).toBe(false)
    expect(store.error).toBeNull()
    expect(store.total).toBe(0)
    expect(store.page).toBe(1)
    expect(store.limit).toBe(20)
    expect(store.totalPages).toBe(0)
  })

  it('fetches all items', async () => {
    const mockData = { items: [{{MOCK_ITEM}}], total: 1, page: 1, limit: 20 }
    mockedService.list.mockResolvedValue(mockData)

    const store = use{{ENTITY}}Store()
    await store.fetchAll()

    expect(mockedService.list).toHaveBeenCalledOnce()
    expect(store.items).toEqual(mockData.items)
    expect(store.total).toBe(1)
    expect(store.loading).toBe(false)
  })

  it('fetches one item by id', async () => {
    const mockItem = {{MOCK_ITEM}}
    mockedService.get.mockResolvedValue(mockItem)

    const store = use{{ENTITY}}Store()
    await store.fetchOne('test-id')

    expect(mockedService.get).toHaveBeenCalledWith('test-id')
    expect(store.current).toEqual(mockItem)
  })

  it('creates an item', async () => {
    const newItem = {{MOCK_ITEM}}
    mockedService.post.mockResolvedValue(newItem)

    const store = use{{ENTITY}}Store()
    const result = await store.create({{MOCK_CREATE_INPUT}})

    expect(mockedService.post).toHaveBeenCalledOnce()
    expect(store.items).toContainEqual(newItem)
    expect(result).toEqual(newItem)
  })

  it('updates an item', async () => {
    const existing = {{MOCK_ITEM}}
    const updated = { ...existing, {{MOCK_UPDATE_FIELD}} }
    mockedService.put.mockResolvedValue(updated)

    const store = use{{ENTITY}}Store()
    store.items = [existing]
    await store.update(existing.id, { {{MOCK_UPDATE_FIELD}} })

    expect(mockedService.put).toHaveBeenCalledWith(existing.id, { {{MOCK_UPDATE_FIELD}} })
    expect(store.items[0]).toEqual(updated)
  })

  it('removes an item', async () => {
    const existing = {{MOCK_ITEM}}
    mockedService.delete.mockResolvedValue(undefined)

    const store = use{{ENTITY}}Store()
    store.items = [existing]
    await store.remove(existing.id)

    expect(mockedService.delete).toHaveBeenCalledWith(existing.id)
    expect(store.items).toHaveLength(0)
  })

  it('handles fetch error', async () => {
    mockedService.list.mockRejectedValue(new Error('Network error'))

    const store = use{{ENTITY}}Store()
    await store.fetchAll()

    expect(store.error).toBe('Network error')
    expect(store.loading).toBe(false)
  })
})
