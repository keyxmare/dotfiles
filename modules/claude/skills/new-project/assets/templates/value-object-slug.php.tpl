<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\ValueObject;

use App\Shared\Domain\Exception\DomainException;

final readonly class Slug
{
    public function __construct(
        public string $value,
    ) {
        if (!preg_match('/^[a-z0-9]+(?:-[a-z0-9]+)*$/', $value)) {
            throw new DomainException(\sprintf('Invalid slug: %s', $value));
        }
    }

    public static function fromString(string $text): self
    {
        $slug = mb_strtolower($text);
        $slug = preg_replace('/[^a-z0-9\s-]/', '', $slug) ?? '';
        $slug = preg_replace('/[\s-]+/', '-', $slug) ?? '';
        $slug = trim($slug, '-');

        return new self($slug);
    }

    public function equals(self $other): bool
    {
        return $this->value === $other->value;
    }

    public function __toString(): string
    {
        return $this->value;
    }
}
