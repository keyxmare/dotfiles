<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\ValueObject;

use App\Shared\Domain\Exception\DomainException;

final readonly class Email
{
    public function __construct(
        public string $value,
    ) {
        if (!filter_var($value, FILTER_VALIDATE_EMAIL)) {
            throw new DomainException(\sprintf('Invalid email: %s', $value));
        }
    }

    public function domain(): string
    {
        return mb_substr($this->value, mb_strpos($this->value, '@') + 1);
    }

    public function equals(self $other): bool
    {
        return mb_strtolower($this->value) === mb_strtolower($other->value);
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
