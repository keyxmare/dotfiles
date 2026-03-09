<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\ValueObject;

final readonly class {{NAME}}
{
    public function __construct(
        public {{TYPE}} $value,
    ) {
        {{VALIDATION}}
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return (string) $this->value;
    }
}
