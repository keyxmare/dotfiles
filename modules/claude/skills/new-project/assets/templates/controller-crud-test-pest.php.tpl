<?php

declare(strict_types=1);

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
use Symfony\Component\HttpFoundation\Response;

uses(WebTestCase::class);

describe('{{ENTITY}}Controller', function () {
    it('lists {{ENTITY_PLURAL_LOWER}}', function () {
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}');

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_OK);
        $data = \json_decode($client->getResponse()->getContent(), true);
        expect($data)->toHaveKey('items');
        expect($data)->toHaveKey('total');
    });

    it('creates a {{ENTITY_LOWER}}', function () {
        $client = static::createClient();
        $client->request(
            'POST',
            '/api/{{ENTITY_PLURAL_KEBAB}}',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            \json_encode({{CREATE_PAYLOAD}})
        );

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_CREATED);
{{CREATE_ASSERTIONS}}
    });

    it('shows a {{ENTITY_LOWER}}', function () {
        {{SETUP_ENTITY}}
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}/' . $id);

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_OK);
{{SHOW_ASSERTIONS}}
    });

    it('returns 404 for unknown {{ENTITY_LOWER}}', function () {
        $client = static::createClient();
        $client->request('GET', '/api/{{ENTITY_PLURAL_KEBAB}}/00000000-0000-0000-0000-000000000000');

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_NOT_FOUND);
    });

    it('updates a {{ENTITY_LOWER}}', function () {
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

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_OK);
{{UPDATE_ASSERTIONS}}
    });

    it('deletes a {{ENTITY_LOWER}}', function () {
        {{SETUP_ENTITY}}
        $client = static::createClient();
        $client->request('DELETE', '/api/{{ENTITY_PLURAL_KEBAB}}/' . $id);

        expect($client->getResponse()->getStatusCode())->toBe(Response::HTTP_NO_CONTENT);
    });
});
