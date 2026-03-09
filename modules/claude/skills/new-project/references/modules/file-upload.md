# Module — file-upload

- `league/flysystem-bundle` dans `composer.json`.
- `config/packages/flysystem.yaml` — adapter `local`, stockage dans `var/uploads/`.
- `UploadController` avec validation taille/type MIME.
- Composant frontend upload drag & drop avec preview.
- Volume Docker pour `var/uploads/` dans `compose.yaml`.
- Configuration max upload size dans `php.ini` (Dockerfile).
