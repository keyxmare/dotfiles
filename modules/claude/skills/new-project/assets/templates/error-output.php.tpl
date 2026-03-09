<?php

declare(strict_types=1);

namespace App\Shared\Application\DTO;

final readonly class ErrorOutput
{
    /**
     * @param array<string, string[]> $violations
     */
    public function __construct(
        public string $message,
        public int $code,
        public array $violations = [],
    ) {
    }
}
