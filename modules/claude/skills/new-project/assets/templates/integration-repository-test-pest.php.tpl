<?php

declare(strict_types=1);

use App\{{CONTEXT}}\Domain\Model\{{ENTITY}};
use App\{{CONTEXT}}\Infrastructure\Persistence\Doctrine\{{ENTITY}}Repository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

uses(KernelTestCase::class);

beforeEach(function () {
    self::bootKernel();
    $this->entityManager = self::getContainer()->get(EntityManagerInterface::class);
    $this->repository = self::getContainer()->get({{ENTITY}}Repository::class);

    $this->entityManager->beginTransaction();
});

afterEach(function () {
    $this->entityManager->rollback();
});

describe('{{ENTITY}}Repository', function () {
    it('can save and find {{ENTITY_SNAKE}}', function () {
        ${{ENTITY_CAMEL}} = {{ENTITY}}::create(
{{CREATE_ARGS}}
        );

        $this->repository->save(${{ENTITY_CAMEL}});

        $found = $this->repository->findById(${{ENTITY_CAMEL}}->id());
        expect($found)->not->toBeNull();
        expect($found->id())->toBe(${{ENTITY_CAMEL}}->id());
{{PROPERTY_ASSERTIONS}}
    });

    it('returns null when {{ENTITY_SNAKE}} not found', function () {
        $found = $this->repository->findById('non-existent-id');
        expect($found)->toBeNull();
    });

    it('can remove {{ENTITY_SNAKE}}', function () {
        ${{ENTITY_CAMEL}} = {{ENTITY}}::create(
{{CREATE_ARGS}}
        );

        $this->repository->save(${{ENTITY_CAMEL}});
        $this->repository->remove(${{ENTITY_CAMEL}});

        $found = $this->repository->findById(${{ENTITY_CAMEL}}->id());
        expect($found)->toBeNull();
    });
});
