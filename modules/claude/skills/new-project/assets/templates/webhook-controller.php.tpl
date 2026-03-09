<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Infrastructure\Controller;

use Psr\Log\LoggerInterface;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/webhooks/{{WEBHOOK_KEBAB}}', name: 'webhook_{{WEBHOOK_SNAKE}}_')]
final readonly class {{WEBHOOK}}WebhookController
{
    public function __construct(
        private MessageBusInterface $commandBus,
        private LoggerInterface $logger,
    ) {
    }

    #[Route('', name: 'handle', methods: ['POST'])]
    public function __invoke(Request $request): JsonResponse
    {
        $payload = $request->toArray();

        {{SIGNATURE_VERIFICATION}}

        $this->logger->info('Webhook received', [
            'webhook' => '{{WEBHOOK_KEBAB}}',
            'event' => $payload['event'] ?? 'unknown',
        ]);

        {{WEBHOOK_DISPATCH}}

        return new JsonResponse(['status' => 'accepted'], Response::HTTP_ACCEPTED);
    }
}
