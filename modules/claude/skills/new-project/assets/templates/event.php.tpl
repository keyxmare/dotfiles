<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\Event;

final readonly class {{ENTITY}}{{ACTION_PAST}}
{
    public function __construct(
        public string ${{ENTITY_CAMEL}}Id,
    ) {
    }
}
