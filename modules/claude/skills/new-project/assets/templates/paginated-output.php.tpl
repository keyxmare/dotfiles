<?php

declare(strict_types=1);

namespace App\{{NAMESPACE}};

final readonly class PaginatedOutput
{
    /**
     * @param array<int, mixed> $items
     */
    public function __construct(
        public array $items,
        public int $total,
        public int $page,
        public int $limit,
    ) {
    }
}
