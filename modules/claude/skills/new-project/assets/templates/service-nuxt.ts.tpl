import type { {{ENTITY}} } from '{{TYPE_IMPORT_PATH}}'

interface PaginatedResult<T> {
  items: T[]
  total: number
  page: number
  limit: number
}

const BASE_URL = '/api/{{CONTEXT_KEBAB}}/{{ENTITY_PLURAL_KEBAB}}'

async function request<T>(url: string, options?: Parameters<typeof $fetch>[1]): Promise<T> {
  return $fetch<T>(url, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  })
}

export const {{ENTITY_CAMEL}}Service = {
  list: (params?: { page?: number; limit?: number }) => {
    const query = new URLSearchParams()
    if (params?.page) query.set('page', String(params.page))
    if (params?.limit) query.set('limit', String(params.limit))
    const qs = query.toString()
    return request<PaginatedResult<{{ENTITY}}>>(`${BASE_URL}${qs ? `?${qs}` : ''}`)
  },
  get: (id: string) => request<{{ENTITY}}>(`${BASE_URL}/${id}`),
  post: (data: Omit<{{ENTITY}}, 'id'>) => request<{{ENTITY}}>(BASE_URL, { method: 'POST', body: data }),
  put: (id: string, data: Partial<{{ENTITY}}>) => request<{{ENTITY}}>(`${BASE_URL}/${id}`, { method: 'PUT', body: data }),
  delete: (id: string) => request<void>(`${BASE_URL}/${id}`, { method: 'DELETE' }),
}
