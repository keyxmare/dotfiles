<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Application\CommandHandler;

use App\{{CONTEXT}}\Application\Command\{{ACTION}}{{ENTITY}}Command;
use App\{{CONTEXT}}\Domain\Repository\{{ENTITY}}RepositoryInterface;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler(bus: 'command.bus')]
final readonly class {{ACTION}}{{ENTITY}}Handler
{
    public function __construct(
        private {{ENTITY}}RepositoryInterface $repository,
    ) {
    }

    public function __invoke({{ACTION}}{{ENTITY}}Command $command): void
    {
        {{HANDLER_BODY}}
    }
}
