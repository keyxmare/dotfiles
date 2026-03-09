<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\Repository;

use App\{{CONTEXT}}\Domain\Model\{{ENTITY}};

interface {{ENTITY}}RepositoryInterface
{
    public function save({{ENTITY}} ${{ENTITY_CAMEL}}): void;

    public function findById(string $id): ?{{ENTITY}};

    /** @return {{ENTITY}}[] */
    public function findAll(): array;

    /** @return array{items: {{ENTITY}}[], total: int} */
    public function findPaginated(int $page = 1, int $limit = 20): array;

    public function remove({{ENTITY}} ${{ENTITY_CAMEL}}): void;
}
