<script setup lang="ts">
{{STORE_IMPORT}}
import type { {{ENTITY}} } from '{{TYPE_IMPORT_PATH}}'

definePageMeta({
  layout: '{{LAYOUT}}',
})

const route = useRoute()
const store = use{{ENTITY}}Store()

const page = computed(() => Number(route.query.page) || 1)
const itemToDelete = ref<{{ENTITY}} | null>(null)

onMounted(() => store.fetchAll({ page: page.value }))
watch(page, (val) => store.fetchAll({ page: val }))

async function handleDelete() {
  if (!itemToDelete.value) return
  await store.remove(itemToDelete.value.id)
  itemToDelete.value = null
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 data-testid="page-title">{{PAGE_TITLE}}</h1>
      <NuxtLink to="{{CREATE_PATH}}" data-testid="create-btn">
        Ajouter
      </NuxtLink>
    </div>

    <div v-if="store.loading" data-testid="loading">Chargement...</div>

    <div v-else-if="store.error" data-testid="error">{{ store.error }}</div>

    <div v-else-if="store.items.length === 0" data-testid="empty-state">
      Aucun élément trouvé.
    </div>

    <template v-else>
      <table data-testid="list-table">
        <thead>
          <tr>
{{TABLE_HEADERS}}
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in store.items" :key="item.id" data-testid="list-item">
{{TABLE_CELLS}}
            <td>
              <NuxtLink :to="`{{DETAIL_PATH_PREFIX}}/${item.id}`" data-testid="view-btn">Voir</NuxtLink>
              <NuxtLink :to="`{{DETAIL_PATH_PREFIX}}/${item.id}/edit`" data-testid="edit-btn">Modifier</NuxtLink>
              <button type="button" data-testid="delete-btn" @click="itemToDelete = item">Supprimer</button>
            </td>
          </tr>
        </tbody>
      </table>

      <nav v-if="store.totalPages > 1" aria-label="Pagination" data-testid="pagination">
        <NuxtLink
          :to="{ query: { ...route.query, page: String(page - 1) } }"
          :class="{ 'pointer-events-none opacity-50': page <= 1 }"
        >
          Précédent
        </NuxtLink>
        <span>{{ page }} / {{ store.totalPages }}</span>
        <NuxtLink
          :to="{ query: { ...route.query, page: String(page + 1) } }"
          :class="{ 'pointer-events-none opacity-50': page >= store.totalPages }"
        >
          Suivant
        </NuxtLink>
      </nav>
    </template>

    <Teleport to="body">
      <div v-if="itemToDelete" data-testid="delete-modal">
        <div>
          <p>Supprimer cet élément ?</p>
          <div>
            <button type="button" data-testid="cancel-delete-btn" @click="itemToDelete = null">Annuler</button>
            <button type="button" data-testid="confirm-delete-btn" @click="handleDelete">Supprimer</button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>
