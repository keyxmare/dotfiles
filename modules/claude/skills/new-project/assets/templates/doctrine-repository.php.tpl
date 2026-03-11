<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Infrastructure\Persistence\Doctrine;

use App\{{CONTEXT}}\Domain\Model\{{ENTITY}};
use App\{{CONTEXT}}\Domain\Repository\{{ENTITY}}RepositoryInterface;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;
use Doctrine\ORM\Tools\Pagination\Paginator;

final readonly class {{ENTITY}}Repository implements {{ENTITY}}RepositoryInterface
{
    /** @var EntityRepository<{{ENTITY}}> */
    private EntityRepository $repository;

    public function __construct(
        private EntityManagerInterface $entityManager,
    ) {
        $this->repository = $this->entityManager->getRepository({{ENTITY}}::class);
    }

    public function save({{ENTITY}} ${{ENTITY_CAMEL}}): void
    {
        $this->entityManager->persist(${{ENTITY_CAMEL}});
        $this->entityManager->flush();
    }

    public function findById(string $id): ?{{ENTITY}}
    {
        return $this->repository->find($id);
    }

    /** @return {{ENTITY}}[] */
    public function findAll(): array
    {
        return $this->repository->findAll();
    }

    /** @return array{items: {{ENTITY}}[], total: int} */
    public function findPaginated(int $page = 1, int $limit = 20): array
    {
        $qb = $this->entityManager->createQueryBuilder()
            ->select('e')
            ->from({{ENTITY}}::class, 'e')
            ->setFirstResult(($page - 1) * $limit)
            ->setMaxResults($limit);

        $paginator = new Paginator($qb);

        return [
            'items' => \iterator_to_array($paginator),
            'total' => $paginator->count(),
        ];
    }

    public function remove({{ENTITY}} ${{ENTITY_CAMEL}}): void
    {
        $this->entityManager->remove(${{ENTITY_CAMEL}});
        $this->entityManager->flush();
    }
}
