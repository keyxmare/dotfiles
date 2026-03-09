<?php

declare(strict_types=1);

namespace App\Service;

use App\Entity\{{ENTITY}};
use App\Repository\{{ENTITY}}Repository;
use Symfony\Component\Uid\Uuid;

final readonly class {{ENTITY}}Service
{
    public function __construct(
        private {{ENTITY}}Repository $repository,
    ) {
    }

    public function create({{CREATE_PARAMS}}): {{ENTITY}}
    {
        $entity = new {{ENTITY}}(
            Uuid::v7()->toRfc4122(),
{{CREATE_ARGS}}
        );
        $this->repository->save($entity);

        return $entity;
    }

    public function get(string $id): {{ENTITY}}
    {
        return $this->repository->findOrFail($id);
    }

    /** @return array{items: {{ENTITY}}[], total: int} */
    public function list(int $page = 1, int $limit = 20): array
    {
        return $this->repository->findPaginated($page, $limit);
    }

    public function update(string $id, {{UPDATE_PARAMS}}): {{ENTITY}}
    {
        $entity = $this->repository->findOrFail($id);
{{UPDATE_CALLS}}
        $this->repository->save($entity);

        return $entity;
    }

    public function delete(string $id): void
    {
        $entity = $this->repository->findOrFail($id);
        $this->repository->remove($entity);
    }
}
