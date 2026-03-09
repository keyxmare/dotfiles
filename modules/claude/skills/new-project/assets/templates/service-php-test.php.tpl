<?php

declare(strict_types=1);

namespace App\Tests\Unit\{{CONTEXT}}\Application\Service;

use App\{{CONTEXT}}\Application\Service\{{NAME}}Service;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\TestCase;

final class {{NAME}}ServiceTest extends TestCase
{
    private {{NAME}}Service $service;

    protected function setUp(): void
    {
{{SETUP_MOCKS}}
        $this->service = new {{NAME}}Service({{CONSTRUCTOR_ARGS}});
    }

    #[Test]
    public function it_{{TEST_DESCRIPTION}}(): void
    {
        {{TEST_BODY}}
    }
}
