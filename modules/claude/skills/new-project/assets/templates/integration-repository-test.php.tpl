<?php

declare(strict_types=1);

namespace App\Tests\Integration\{{CONTEXT}}\Infrastructure\Persistence\Doctrine;

use App\{{CONTEXT}}\Domain\Model\{{ENTITY}};
use App\{{CONTEXT}}\Infrastructure\Persistence\Doctrine\{{ENTITY}}Repository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

final class {{ENTITY}}RepositoryTest extends KernelTestCase
{
    private EntityManagerInterface $entityManager;
    private {{ENTITY}}Repository $repository;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->entityManager = self::getContainer()->get(EntityManagerInterface::class);
        $this->repository = self::getContainer()->get({{ENTITY}}Repository::class);

        $this->entityManager->beginTransaction();
    }

    protected function tearDown(): void
    {
        $this->entityManager->rollback();
        parent::tearDown();
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_can_save_and_find_{{ENTITY_SNAKE}}(): void
    {
        ${{ENTITY_CAMEL}} = {{ENTITY}}::create(
{{CREATE_ARGS}}
        );

        $this->repository->save(${{ENTITY_CAMEL}});

        $found = $this->repository->findById(${{ENTITY_CAMEL}}->id());
        self::assertNotNull($found);
        self::assertSame(${{ENTITY_CAMEL}}->id(), $found->id());
{{PROPERTY_ASSERTIONS}}
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_returns_null_when_{{ENTITY_SNAKE}}_not_found(): void
    {
        $found = $this->repository->findById('non-existent-id');
        self::assertNull($found);
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_can_remove_{{ENTITY_SNAKE}}(): void
    {
        ${{ENTITY_CAMEL}} = {{ENTITY}}::create(
{{CREATE_ARGS}}
        );

        $this->repository->save(${{ENTITY_CAMEL}});
        $this->repository->remove(${{ENTITY_CAMEL}});

        $found = $this->repository->findById(${{ENTITY_CAMEL}}->id());
        self::assertNull($found);
    }
}
