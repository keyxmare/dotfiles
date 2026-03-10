<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
{{STORE_IMPORT}}
import type { {{ENTITY}} } from '{{TYPE_IMPORT_PATH}}'

const route = useRoute()
const router = useRouter()
const store = use{{ENTITY}}Store()

const page = computed(() => Number(route.query.page) || 1)
const itemToDelete = ref<{{ENTITY}} | null>(null)

onMounted(() => store.fetchAll({ page: page.value }))
watch(page, (val) => store.fetchAll({ page: val }))

function goToPage(p: number) {
  router.push({ query: { ...route.query, page: String(p) } })
}

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
      <RouterLink :to="{ name: '{{ROUTE_NAME_CREATE}}' }" data-testid="create-btn">
        Ajouter
      </RouterLink>
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
              <RouterLink :to="{ name: '{{ROUTE_NAME_DETAIL}}', params: { id: item.id } }" data-testid="view-btn">Voir</RouterLink>
              <RouterLink :to="{ name: '{{ROUTE_NAME_EDIT}}', params: { id: item.id } }" data-testid="edit-btn">Modifier</RouterLink>
              <button type="button" data-testid="delete-btn" @click="itemToDelete = item">Supprimer</button>
            </td>
          </tr>
        </tbody>
      </table>

      <nav v-if="store.totalPages > 1" aria-label="Pagination" data-testid="pagination">
        <button :disabled="page <= 1" @click="goToPage(page - 1)">Précédent</button>
        <span>{{ page }} / {{ store.totalPages }}</span>
        <button :disabled="page >= store.totalPages" @click="goToPage(page + 1)">Suivant</button>
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
