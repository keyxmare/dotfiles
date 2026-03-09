<?php

declare(strict_types=1);

namespace App\Tests\Unit\{{TARGET_CONTEXT}}\Application\EventListener;

use App\{{SOURCE_CONTEXT}}\Domain\Event\{{EVENT}};
use App\{{TARGET_CONTEXT}}\Application\EventListener\On{{EVENT}}Listener;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class On{{EVENT}}ListenerTest extends TestCase
{
    private On{{EVENT}}Listener $listener;

    protected function setUp(): void
    {
{{SETUP_MOCKS}}
        $this->listener = new On{{EVENT}}Listener({{CONSTRUCTOR_ARGS}});
    }

    #[Test]
    public function it_{{TEST_DESCRIPTION}}(): void
    {
        $event = new {{EVENT}}({{EVENT_ARGS}});

        ($this->listener)($event);

        {{ASSERTIONS}}
    }
}
