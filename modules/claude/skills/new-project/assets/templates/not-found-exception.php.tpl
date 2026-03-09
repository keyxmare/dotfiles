<?php

declare(strict_types=1);

namespace App\Shared\Domain\Exception;

final class NotFoundException extends DomainException
{
    public static function forEntity(string $entity, string $id): self
    {
        return new self(sprintf('%s with id "%s" not found.', $entity, $id));
    }
}
