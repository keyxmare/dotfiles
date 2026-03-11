<?php

declare(strict_types=1);

namespace App\Tests\Functional\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

final class {{ENTITY}}ControllerTest extends WebTestCase
{
    #[\PHPUnit\Framework\Attributes\Test]
    public function it_lists_{{ENTITY_PLURAL_LOWER}}(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}');

        self::assertResponseStatusCodeSame(Response::HTTP_OK);
        $data = \json_decode($client->getResponse()->getContent(), true);
        self::assertArrayHasKey('items', $data);
        self::assertArrayHasKey('total', $data);
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_creates_a_{{ENTITY_LOWER}}(): void
    {
        $client = static::createClient();
        $client->request(
            'POST',
            '/api/{{ENTITY_PLURAL_KEBAB}}',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            \json_encode({{CREATE_PAYLOAD}})
        );

        self::assertResponseStatusCodeSame(Response::HTTP_CREATED);
{{CREATE_ASSERTIONS}}
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_shows_a_{{ENTITY_LOWER}}(): void
    {
        {{SETUP_ENTITY}}
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}/' . $id);

        self::assertResponseStatusCodeSame(Response::HTTP_OK);
{{SHOW_ASSERTIONS}}
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_returns_404_for_unknown_{{ENTITY_LOWER}}(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}/00000000-0000-0000-0000-000000000000');

        self::assertResponseStatusCodeSame(Response::HTTP_NOT_FOUND);
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_updates_a_{{ENTITY_LOWER}}(): void
    {
        {{SETUP_ENTITY}}
        $client = static::createClient();
        $client->request(
            'PUT',
            '/api/{{ENTITY_PLURAL_KEBAB}}/' . $id,
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            \json_encode({{UPDATE_PAYLOAD}})
        );

        self::assertResponseStatusCodeSame(Response::HTTP_OK);
{{UPDATE_ASSERTIONS}}
    }

    #[\PHPUnit\Framework\Attributes\Test]
    public function it_deletes_a_{{ENTITY_LOWER}}(): void
    {
        {{SETUP_ENTITY}}
        $client = static::createClient();
        $client->request('DELETE', '/api/{{ENTITY_PLURAL_KEBAB}}/' . $id);

        self::assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT);
    }
}
