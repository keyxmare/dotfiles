<?php

declare(strict_types=1);

use App\{{CONTEXT}}\Application\Service\{{NAME}}Service;

beforeEach(function () {
{{SETUP_MOCKS}}
    $this->service = new {{NAME}}Service({{CONSTRUCTOR_ARGS}});
});

describe('{{NAME}}Service', function () {
    it('{{TEST_DESCRIPTION}}', function () {
        {{TEST_BODY}}
    });
});
