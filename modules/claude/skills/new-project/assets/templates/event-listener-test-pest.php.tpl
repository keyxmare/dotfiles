<?php

declare(strict_types=1);

use App\{{SOURCE_CONTEXT}}\Domain\Event\{{EVENT}};
use App\{{TARGET_CONTEXT}}\Application\EventListener\On{{EVENT}}Listener;

beforeEach(function () {
{{SETUP_MOCKS}}
    $this->listener = new On{{EVENT}}Listener({{CONSTRUCTOR_ARGS}});
});

describe('On{{EVENT}}Listener', function () {
    it('{{TEST_DESCRIPTION}}', function () {
        $event = new {{EVENT}}({{EVENT_ARGS}});

        ($this->listener)($event);

        {{ASSERTIONS}}
    });
});
