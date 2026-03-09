<?php

declare(strict_types=1);

namespace App\{{TARGET_CONTEXT}}\Application\EventListener;

use App\{{SOURCE_CONTEXT}}\Domain\Event\{{EVENT}};
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler(bus: 'event.bus')]
final readonly class On{{EVENT}}Listener
{
    public function __construct(
{{DEPENDENCIES}}
    ) {
    }

    public function __invoke({{EVENT}} $event): void
    {
        {{LISTENER_BODY}}
    }
}
