<?php

declare(strict_types=1);

use App\{{CONTEXT}}\Application\Query\{{ACTION}}{{ENTITY}}Query;
use App\{{CONTEXT}}\Application\QueryHandler\{{ACTION}}{{ENTITY}}Handler;
use App\{{CONTEXT}}\Domain\Repository\{{ENTITY}}RepositoryInterface;

beforeEach(function () {
    $this->repository = Mockery::mock({{ENTITY}}RepositoryInterface::class);
    $this->handler = new {{ACTION}}{{ENTITY}}Handler($this->repository);
});

describe('{{ACTION}}{{ENTITY}}Handler', function () {
    it('{{TEST_DESCRIPTION}}', function () {
        {{TEST_BODY}}
    });
});
