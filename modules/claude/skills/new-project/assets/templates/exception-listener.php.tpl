<?php

declare(strict_types=1);

namespace App\Shared\Infrastructure\EventListener;

use App\Shared\Application\DTO\ErrorOutput;
use App\Shared\Domain\Exception\DomainException;
use App\Shared\Domain\Exception\NotFoundException;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\Validator\Exception\ValidationFailedException;

final class ExceptionListener
{
    public function __invoke(ExceptionEvent $event): void
    {
        $exception = $event->getThrowable();

        $output = match (true) {
            $exception instanceof NotFoundException => new ErrorOutput(
                message: $exception->getMessage(),
                code: Response::HTTP_NOT_FOUND,
            ),
            $exception instanceof ValidationFailedException => new ErrorOutput(
                message: 'Validation failed',
                code: Response::HTTP_UNPROCESSABLE_ENTITY,
                violations: $this->formatViolations($exception),
            ),
            $exception instanceof DomainException => new ErrorOutput(
                message: $exception->getMessage(),
                code: Response::HTTP_BAD_REQUEST,
            ),
            $exception instanceof HttpExceptionInterface => new ErrorOutput(
                message: $exception->getMessage(),
                code: $exception->getStatusCode(),
            ),
            default => new ErrorOutput(
                message: 'Internal server error',
                code: Response::HTTP_INTERNAL_SERVER_ERROR,
            ),
        };

        $event->setResponse(new JsonResponse(
            data: $output,
            status: $output->code,
        ));
    }

    /**
     * @return array<string, string[]>
     */
    private function formatViolations(ValidationFailedException $exception): array
    {
        $violations = [];
        foreach ($exception->getViolations() as $violation) {
            $field = $violation->getPropertyPath();
            $violations[$field][] = (string) $violation->getMessage();
        }

        return $violations;
    }
}
