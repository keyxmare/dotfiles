<?php

declare(strict_types=1);

namespace App\{{NAMESPACE}};

final readonly class ApiResponse
{
    /**
     * @param array<string, mixed>|null $meta
     * @param array<int, string> $errors
     */
    public function __construct(
        public mixed $data = null,
        public ?array $meta = null,
        public array $errors = [],
    ) {
    }

    /**
     * @param array<string, mixed>|null $meta
     */
    public static function success(mixed $data, ?array $meta = null): self
    {
        return new self(data: $data, meta: $meta);
    }

    /**
     * @param array<int, string> $errors
     */
    public static function error(array $errors): self
    {
        return new self(errors: $errors);
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(): array
    {
        $result = [];
        if ($this->data !== null) {
            $result['data'] = $this->data;
        }
        if ($this->meta !== null) {
            $result['meta'] = $this->meta;
        }
        if ($this->errors !== []) {
            $result['errors'] = $this->errors;
        }

        return $result;
    }
}
