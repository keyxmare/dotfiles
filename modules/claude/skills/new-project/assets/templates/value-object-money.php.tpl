<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\ValueObject;

use App\Shared\Domain\Exception\DomainException;

final readonly class Money
{
    public function __construct(
        public int $amount,
        public string $currency = 'EUR',
    ) {
        if ($amount < 0) {
            throw new DomainException('Money amount cannot be negative');
        }

        if (mb_strlen($currency) !== 3) {
            throw new DomainException(\sprintf('Invalid currency code: %s', $currency));
        }
    }

    public function add(self $other): self
    {
        $this->assertSameCurrency($other);

        return new self($this->amount + $other->amount, $this->currency);
    }

    public function subtract(self $other): self
    {
        $this->assertSameCurrency($other);

        if ($other->amount > $this->amount) {
            throw new DomainException('Cannot subtract: result would be negative');
        }

        return new self($this->amount - $other->amount, $this->currency);
    }

    public function multiply(int $factor): self
    {
        return new self($this->amount * $factor, $this->currency);
    }

    public function equals(self $other): bool
    {
        return $this->amount === $other->amount && $this->currency === $other->currency;
    }

    public function toFloat(): float
    {
        return $this->amount / 100;
    }

    public function __toString(): string
    {
        return \sprintf('%.2f %s', $this->toFloat(), $this->currency);
    }

    private function assertSameCurrency(self $other): void
    {
        if ($this->currency !== $other->currency) {
            throw new DomainException(\sprintf(
                'Cannot operate on different currencies: %s vs %s',
                $this->currency,
                $other->currency,
            ));
        }
    }
}
