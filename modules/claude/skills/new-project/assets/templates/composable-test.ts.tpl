import { describe, it, expect } from 'vitest'
import { use{{NAME}} } from '{{COMPOSABLE_PATH}}'

describe('use{{NAME}}', () => {
  it('{{TEST_DESCRIPTION}}', () => {
    const result = use{{NAME}}({{TEST_ARGS}})

    {{ASSERTIONS}}
  })
})
