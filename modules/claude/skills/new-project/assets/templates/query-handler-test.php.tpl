<?php

declare(strict_types=1);

namespace App\Tests\Unit\{{CONTEXT}}\Application\QueryHandler;

use App\{{CONTEXT}}\Application\Query\{{ACTION}}{{ENTITY}}Query;
use App\{{CONTEXT}}\Application\QueryHandler\{{ACTION}}{{ENTITY}}Handler;
use App\{{CONTEXT}}\Domain\Repository\{{ENTITY}}RepositoryInterface;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\TestCase;

final class {{ACTION}}{{ENTITY}}HandlerTest extends TestCase
{
    private {{ENTITY}}RepositoryInterface&MockObject $repository;
    private {{ACTION}}{{ENTITY}}Handler $handler;

    protected function setUp(): void
    {
        $this->repository = $this->createMock({{ENTITY}}RepositoryInterface::class);
        $this->handler = new {{ACTION}}{{ENTITY}}Handler($this->repository);
    }

    #[Test]
    public function it_{{TEST_DESCRIPTION}}(): void
    {
        {{TEST_BODY}}
    }
}
