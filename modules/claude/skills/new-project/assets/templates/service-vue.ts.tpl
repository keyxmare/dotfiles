import type { {{ENTITY}} } from '{{TYPE_IMPORT_PATH}}'

interface PaginatedResult<T> {
  items: T[]
  total: number
  page: number
  limit: number
}

const BASE_URL = '/api/{{CONTEXT_KEBAB}}/{{ENTITY_PLURAL_KEBAB}}'

async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    headers: { 'Content-Type': 'application/json', ...options?.headers },
    ...options,
  })
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}: ${response.statusText}`)
  }
  return response.json()
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
  post: (data: Omit<{{ENTITY}}, 'id'>) => request<{{ENTITY}}>(BASE_URL, { method: 'POST', body: JSON.stringify(data) }),
  put: (id: string, data: Partial<{{ENTITY}}>) => request<{{ENTITY}}>(`${BASE_URL}/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => request<void>(`${BASE_URL}/${id}`, { method: 'DELETE' }),
}
