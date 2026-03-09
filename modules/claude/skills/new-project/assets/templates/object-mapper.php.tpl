<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\Mapper;

use Symfony\Component\ObjectMapper\ObjectMapperInterface;
use Symfony\Component\ObjectMapper\ObjectMapper;

final readonly class AppObjectMapper
{
    private ObjectMapperInterface $mapper;

    public function __construct()
    {
        $this->mapper = new ObjectMapper();
    }

    /**
     * @template T of object
     * @param class-string<T> $target
     * @return T
     */
    public function map(object $source, string $target): object
    {
        return $this->mapper->map($source, $target);
    }
}
