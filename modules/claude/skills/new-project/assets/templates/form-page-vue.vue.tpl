<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
{{STORE_IMPORT}}
import type { {{ENTITY}} } from '{{TYPE_IMPORT_PATH}}'
{{RELATION_IMPORTS}}

const route = useRoute()
const router = useRouter()
const store = use{{ENTITY}}Store()

const isEdit = computed(() => !!route.params.id)
const id = computed(() => route.params.id as string | undefined)

const form = ref<{{FORM_TYPE}}>({
{{FORM_DEFAULTS}}
})

{{RELATION_FETCHES}}

onMounted(async () => {
  if (isEdit.value && id.value) {
    await store.fetchOne(id.value)
    if (store.current) {
      form.value = { {{FORM_COPY_FROM_CURRENT}} }
    }
  }
})

async function onSubmit() {
  if (isEdit.value && id.value) {
    await store.update(id.value, form.value)
  } else {
    await store.create(form.value)
  }
  router.push({ name: '{{ROUTE_NAME_LIST}}' })
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-6">
      <h1 data-testid="page-title">{{ isEdit ? '{{EDIT_TITLE}}' : '{{CREATE_TITLE}}' }}</h1>
      <RouterLink :to="{ name: '{{ROUTE_NAME_LIST}}' }" data-testid="back-btn">Retour</RouterLink>
    </div>

    <form data-testid="entity-form" @submit.prevent="onSubmit">
{{FORM_FIELDS}}

      <div>
        <button type="submit" :disabled="store.loading" data-testid="submit-btn">
          {{ isEdit ? 'Modifier' : 'Créer' }}
        </button>
      </div>

      <div v-if="store.error" data-testid="error">
        {{ store.error }}
      </div>
    </form>
  </div>
</template>
