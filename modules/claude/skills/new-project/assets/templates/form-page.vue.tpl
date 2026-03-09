<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { use{{STORE}}Store } from '../stores/{{STORE_KEBAB}}'
import type { {{ENTITY}} } from '../types/{{ENTITY_KEBAB}}'

const route = useRoute()
const router = useRouter()
const store = use{{STORE}}Store()

const isEdit = ref(false)
const form = ref<{{FORM_TYPE}}>({
{{FORM_DEFAULTS}}
})

onMounted(async () => {
  const id = route.params.id as string | undefined
  if (id) {
    isEdit.value = true
    await store.fetchOne(id)
    if (store.current) {
      form.value = { ...store.current }
    }
  }
})

async function onSubmit() {
  if (isEdit.value) {
    const id = route.params.id as string
    await store.update(id, form.value)
  } else {
    await store.create(form.value)
  }
  router.push('{{REDIRECT_PATH}}')
}
</script>

<template>
  <div>
    <h1>{{ isEdit ? '{{EDIT_TITLE}}' : '{{CREATE_TITLE}}' }}</h1>

    <form @submit.prevent="onSubmit">
{{FORM_FIELDS}}

      <div>
        <button type="submit" :disabled="store.loading">
          {{ isEdit ? 'Modifier' : 'Créer' }}
        </button>
      </div>

      <div v-if="store.error">
        {{ store.error }}
      </div>
    </form>
  </div>
</template>
