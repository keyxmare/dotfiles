<?php

declare(strict_types=1);

namespace App\Tests\Factory\{{CONTEXT}};

use App\{{CONTEXT}}\Domain\Model\{{ENTITY}};
use Symfony\Component\Uid\Uuid;

final class {{ENTITY}}Factory
{
    /**
     * @param array<string, mixed> $overrides
     */
    public static function create(array $overrides = []): {{ENTITY}}
    {
        return {{ENTITY}}::create(
            id: $overrides['id'] ?? Uuid::v7()->toRfc4122(),
{{FACTORY_DEFAULTS}}
        );
    }

    /**
     * @param array<string, mixed> $overrides
     * @return array<int, {{ENTITY}}>
     */
    public static function createMany(int $count, array $overrides = []): array
    {
        return \array_map(
            fn () => self::create($overrides),
            \range(1, $count),
        );
    }
}
