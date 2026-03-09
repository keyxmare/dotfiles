<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Application\QueryHandler;

use App\{{CONTEXT}}\Application\Query\{{ACTION}}{{ENTITY}}Query;
use App\{{CONTEXT}}\Application\DTO\{{ENTITY}}Output;
use App\{{CONTEXT}}\Domain\Repository\{{ENTITY}}RepositoryInterface;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler(bus: 'query.bus')]
final readonly class {{ACTION}}{{ENTITY}}Handler
{
    public function __construct(
        private {{ENTITY}}RepositoryInterface $repository,
    ) {
    }

    public function __invoke({{ACTION}}{{ENTITY}}Query $query): {{RETURN_TYPE}}
    {
        {{HANDLER_BODY}}
    }
}
