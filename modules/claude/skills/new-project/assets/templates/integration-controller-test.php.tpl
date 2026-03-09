<?php

declare(strict_types=1);

namespace App\Tests\Functional\{{CONTEXT}}\Infrastructure\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

final class {{ACTION}}{{ENTITY}}ControllerTest extends WebTestCase
{
    #[\PHPUnit\Framework\Attributes\Test]
    public function it_{{TEST_DESCRIPTION}}(): void
    {
        $client = static::createClient();

        $client->request(
            '{{HTTP_METHOD}}',
            '/api/{{CONTEXT_KEBAB}}/{{ENTITY_PLURAL_KEBAB}}{{ROUTE_SUFFIX}}',
{{REQUEST_BODY}}
        );

        self::assertResponseStatusCodeSame({{EXPECTED_STATUS}});
{{RESPONSE_ASSERTIONS}}
    }
}
