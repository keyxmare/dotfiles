<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Application\DTO;

use Symfony\Component\Validator\Constraints as Assert;

final readonly class Patch{{ENTITY}}Input
{
    public function __construct(
{{NULLABLE_PROPERTIES}}
    ) {
    }

    public function hasChanges(): bool
    {
        return {{HAS_CHANGES_CONDITION}};
    }
}
