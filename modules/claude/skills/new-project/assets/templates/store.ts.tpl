import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { {{ENTITY}} } from '../types/{{ENTITY_KEBAB}}'
import { {{ENTITY_CAMEL}}Service } from '../services/{{ENTITY_KEBAB}}.service'

export const use{{ENTITY}}Store = defineStore('{{ENTITY_CAMEL}}', () => {
  const items = ref<{{ENTITY}}[]>([])
  const current = ref<{{ENTITY}} | null>(null)
  const loading = ref(false)
  const error = ref<string | null>(null)
  const total = ref(0)
  const page = ref(1)
  const limit = ref(20)

  const totalPages = computed(() => Math.ceil(total.value / limit.value))

  async function fetchAll(params?: { page?: number; limit?: number }) {
    loading.value = true
    error.value = null
    try {
      const result = await {{ENTITY_CAMEL}}Service.list(params)
      items.value = result.items
      total.value = result.total
      page.value = result.page
      limit.value = result.limit
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  async function fetchOne(id: string) {
    loading.value = true
    error.value = null
    try {
      current.value = await {{ENTITY_CAMEL}}Service.get(id)
    } catch (e) {
      error.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  async function create(data: Omit<{{ENTITY}}, 'id'>) {
    loading.value = true
    error.value = null
    try {
      const created = await {{ENTITY_CAMEL}}Service.post(data)
      items.value.push(created)
      return created
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function update(id: string, data: Partial<{{ENTITY}}>) {
    loading.value = true
    error.value = null
    try {
      const updated = await {{ENTITY_CAMEL}}Service.put(id, data)
      const index = items.value.findIndex((item) => item.id === id)
      if (index !== -1) items.value[index] = updated
      return updated
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  async function remove(id: string) {
    loading.value = true
    error.value = null
    try {
      await {{ENTITY_CAMEL}}Service.delete(id)
      items.value = items.value.filter((item) => item.id !== id)
    } catch (e) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  return { items, current, loading, error, total, page, limit, totalPages, fetchAll, fetchOne, create, update, remove }
})
