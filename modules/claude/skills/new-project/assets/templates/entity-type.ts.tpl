export interface {{ENTITY}} {
  id: string
{{PROPERTIES}}
}

export type Create{{ENTITY}}Input = Omit<{{ENTITY}}, 'id'>

export type Update{{ENTITY}}Input = Partial<Create{{ENTITY}}Input>
