<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class ReadinessController
{
    #[Route('/readyz', name: 'readiness', methods: ['GET'])]
    public function __invoke(): JsonResponse
    {
        return new JsonResponse(
            ['status' => 'ready'],
            Response::HTTP_OK,
        );
    }
}
