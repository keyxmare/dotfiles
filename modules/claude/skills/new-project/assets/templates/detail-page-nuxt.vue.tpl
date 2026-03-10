<script setup lang="ts">
{{STORE_IMPORT}}

definePageMeta({
  layout: '{{LAYOUT}}',
})

const route = useRoute()
const store = use{{ENTITY}}Store()

const id = computed(() => route.params.id as string)

onMounted(() => store.fetchOne(id.value))

const entity = computed(() => store.current)
</script>

<template>
  <div>
    <div v-if="store.loading" data-testid="loading">Chargement...</div>

    <div v-else-if="store.error" data-testid="error">{{ store.error }}</div>

    <div v-else-if="entity" data-testid="entity-detail">
      <div class="flex items-center justify-between mb-6">
        <h1 data-testid="page-title">{{DETAIL_TITLE}}</h1>
        <div>
          <NuxtLink :to="`{{DETAIL_PATH_PREFIX}}/${entity.id}/edit`" data-testid="edit-btn">
            Modifier
          </NuxtLink>
          <NuxtLink to="{{LIST_PATH}}" data-testid="back-btn">
            Retour
          </NuxtLink>
        </div>
      </div>

      <dl>
{{DETAIL_FIELDS}}
      </dl>
    </div>
  </div>
</template>
