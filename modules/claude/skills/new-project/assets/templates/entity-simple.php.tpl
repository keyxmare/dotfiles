<?php

declare(strict_types=1);

namespace App\Entity;

use App\Repository\{{ENTITY}}Repository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity(repositoryClass: {{ENTITY}}Repository::class)]
#[ORM\Table(name: '{{TABLE_NAME}}')]
final class {{ENTITY}}
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid')]
    private string $id;

{{ORM_PROPERTIES}}

    public function __construct(
        string $id,
{{CONSTRUCTOR_PARAMS}}
    ) {
        $this->id = $id;
{{CONSTRUCTOR_ASSIGNMENTS}}
    }

    public function id(): string
    {
        return $this->id;
    }

{{GETTERS_SETTERS}}
}
