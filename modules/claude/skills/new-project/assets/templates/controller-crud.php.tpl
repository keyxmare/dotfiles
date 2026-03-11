<?php

declare(strict_types=1);

namespace App\Controller;

use App\Service\{{ENTITY}}Service;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/{{ENTITY_PLURAL_KEBAB}}', name: '{{ROUTE_PREFIX}}_')]
final readonly class {{ENTITY}}Controller
{
    public function __construct(
        private {{ENTITY}}Service $service,
    ) {
    }

    #[Route('', name: 'list', methods: ['GET'])]
    public function index(Request $request): JsonResponse
    {
        $page = $request->query->getInt('page', 1);
        $limit = $request->query->getInt('limit', 20);
        $result = $this->service->list($page, $limit);

        return new JsonResponse([
            'items' => \array_map(fn ($item) => {{OUTPUT_TRANSFORM}}, $result['items']),
            'total' => $result['total'],
            'page' => $page,
            'limit' => $limit,
        ]);
    }

    #[Route('/{id}', name: 'show', methods: ['GET'])]
    public function show(string $id): JsonResponse
    {
        $entity = $this->service->get($id);

        return new JsonResponse({{SINGLE_OUTPUT_TRANSFORM}});
    }

    #[Route('', name: 'create', methods: ['POST'])]
    public function create(Request $request): JsonResponse
    {
        $data = \json_decode($request->getContent(), true, 512, \JSON_THROW_ON_ERROR);
{{VALIDATE_CREATE}}
        $entity = $this->service->create({{CREATE_CALL_ARGS}});

        return new JsonResponse({{SINGLE_OUTPUT_TRANSFORM}}, Response::HTTP_CREATED);
    }

    #[Route('/{id}', name: 'update', methods: ['PUT'])]
    public function update(string $id, Request $request): JsonResponse
    {
        $data = \json_decode($request->getContent(), true, 512, \JSON_THROW_ON_ERROR);
{{VALIDATE_UPDATE}}
        $entity = $this->service->update($id, {{UPDATE_CALL_ARGS}});

        return new JsonResponse({{SINGLE_OUTPUT_TRANSFORM}});
    }

    #[Route('/{id}', name: 'destroy', methods: ['DELETE'])]
    public function destroy(string $id): JsonResponse
    {
        $this->service->delete($id);

        return new JsonResponse(null, Response::HTTP_NO_CONTENT);
    }
}
