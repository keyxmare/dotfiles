<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { use{{STORE}}Store } from '../stores/{{STORE_KEBAB}}'

const route = useRoute()
const router = useRouter()
const store = use{{STORE}}Store()

function loadPage(page: number) {
  store.fetchAll({ page, limit: store.limit })
}

function goToPage(page: number) {
  router.push({ query: { ...route.query, page: String(page) } })
}

onMounted(() => {
  const page = Number(route.query.page) || 1
  loadPage(page)
})

watch(() => route.query.page, (val) => {
  loadPage(Number(val) || 1)
})
</script>

<template>
  <div>
    <h1>{{PAGE_TITLE}}</h1>

    <div v-if="store.loading">Chargement...</div>

    <div v-else-if="store.error">
      {{ store.error }}
    </div>

    <div v-else-if="store.items.length === 0">
      Aucun élément trouvé.
    </div>

    <div v-else>
      {{CONTENT}}

      <nav v-if="store.totalPages > 1" aria-label="Pagination">
        <button :disabled="store.page <= 1" @click="goToPage(store.page - 1)">
          Précédent
        </button>
        <span>{{ store.page }} / {{ store.totalPages }}</span>
        <button :disabled="store.page >= store.totalPages" @click="goToPage(store.page + 1)">
          Suivant
        </button>
      </nav>
    </div>
  </div>
</template>
