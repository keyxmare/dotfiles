<?php

declare(strict_types=1);

namespace App\{{CONTEXT}}\Domain\Model;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
{{EVENT_IMPORTS}}

#[ORM\Entity]
#[ORM\Table(name: '{{TABLE_NAME}}')]
final class {{ENTITY}}
{
    /** @var object[] */
    private array $domainEvents = [];

    #[ORM\Id]
    #[ORM\Column(type: 'uuid')]
    private readonly string $id;

{{ORM_PROPERTIES}}

    private function __construct(
        string $id,
{{CONSTRUCTOR_PARAMS}}
    ) {
        $this->id = $id;
{{CONSTRUCTOR_ASSIGNMENTS}}
    }

    public static function create(
        string $id,
{{CONSTRUCTOR_PARAMS}}
    ): self {
        $entity = new self($id, {{PROPERTY_ARGS}});
        $entity->raise(new {{ENTITY}}Created($entity->id()));

        return $entity;
    }
{{UPDATE_METHODS}}
    public function id(): string
    {
        return $this->id;
    }

{{GETTERS}}

    /** @return object[] */
    public function pullDomainEvents(): array
    {
        $events = $this->domainEvents;
        $this->domainEvents = [];

        return $events;
    }

    private function raise(object $event): void
    {
        $this->domainEvents[] = $event;
    }
}
