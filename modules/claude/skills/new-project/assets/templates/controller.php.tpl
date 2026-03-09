<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Infrastructure\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Routing\Attribute\Route;
{{EXTRA_IMPORTS}}

#[Route('/api/{{CONTEXT_KEBAB}}/{{ENTITY_PLURAL_KEBAB}}', name: '{{ROUTE_PREFIX}}_')]
final readonly class {{ACTION}}{{ENTITY}}Controller
{
    public function __construct(
        private MessageBusInterface ${{BUS_TYPE}}Bus,
    ) {
    }

    #[Route('{{ROUTE_SUFFIX}}', name: '{{ACTION_LOWER}}', methods: ['{{HTTP_METHOD}}'])]
    public function __invoke({{INVOKE_PARAMS}}): JsonResponse
    {
        {{CONTROLLER_BODY}}
    }
{{HELPER_METHODS}}
}
