<?php

declare(strict_types=1);

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

uses(WebTestCase::class);

describe('{{ACTION}}{{ENTITY}}Controller', function () {
    it('{{TEST_DESCRIPTION}}', function () {
        $client = static::createClient();

        $client->request(
            '{{HTTP_METHOD}}',
            '/api/{{CONTEXT_KEBAB}}/{{ENTITY_PLURAL_KEBAB}}{{ROUTE_SUFFIX}}',
{{REQUEST_BODY}}
        );

        expect($client->getResponse()->getStatusCode())->toBe({{EXPECTED_STATUS}});
{{RESPONSE_ASSERTIONS}}
    });
});
