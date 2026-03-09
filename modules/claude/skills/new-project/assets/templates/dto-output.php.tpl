<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Application\DTO;

final readonly class {{ENTITY}}Output
{
    public function __construct(
        public string $id,
{{PROPERTIES}}
    ) {
    }

    public static function from{{ENTITY}}({{ENTITY_FQCN}} ${{ENTITY_CAMEL}}): self
    {
        return new self(
            id: ${{ENTITY_CAMEL}}->id(),
{{PROPERTY_MAPPINGS}}
        );
    }
}
