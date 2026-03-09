<?php

declare(strict_types=1);

namespace App\Tests\Unit\{{CONTEXT}}\Application\CommandHandler;

use App\{{CONTEXT}}\Application\Command\{{ACTION}}{{ENTITY}}Command;
use App\{{CONTEXT}}\Application\CommandHandler\{{ACTION}}{{ENTITY}}Handler;
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
