# linux-pkg-recovery

Recuperador de paquetes para sistemas basados en Ubuntu/Debian. Pensado para el caso de dual boot Windows + Ubuntu: antes de formatear/reinstalar Ubuntu corres `backup.sh` para dejar un snapshot de lo que tienes instalado, subes ese snapshot a GitHub, y en el sistema limpio corres `restore.sh` para reinstalar todo automáticamente.

## Qué respalda

- Paquetes `apt` instalados manualmente (`apt-mark showmanual`)
- Paquetes `snap`
- Paquetes `flatpak`
- Paquetes `pip` de usuario y herramientas `pipx`
- Paquetes `npm` globales
- Extensiones de VS Code
- Configuración de Git (`~/.gitconfig`, sin el email por defecto)
- Versión instalada de Claude Code (se reinstala vía npm si falta)

## Qué NO respalda (a propósito)

- **Llaves SSH privadas ni tokens de autenticación.** Este repo es público, así que nunca se sube nada de eso. `restore.sh` genera una llave SSH nueva en cada instalación limpia y te muestra la clave pública para pegarla en GitHub.
- Dotfiles generales (`.bashrc`, temas, atajos) — queda fuera del alcance de la v1.

## Uso

### Antes de reinstalar (en el sistema actual)

```bash
./backup.sh
# o, si quieres incluir tu email de git en el respaldo:
./backup.sh --with-email

git add manifests/
git commit -m "Actualiza snapshot de paquetes"
git push
```

### Después de instalar Ubuntu limpio

```bash
git clone https://github.com/<tu-usuario>/linux-pkg-recovery.git
cd linux-pkg-recovery
chmod +x restore.sh
./restore.sh
```

El script instala todo lo que encuentra en `manifests/`, avisa qué falló (por ejemplo snaps que necesitan `--classic`, o paquetes que ya no existen en los repos) y al final genera la llave SSH nueva para GitHub.

## Notas

- Pensado para Ubuntu/Debian; usa `apt` como gestor base. No cubre otras distros por ahora.
- Es seguro correr `backup.sh` varias veces: sobreescribe los manifiestos con el estado actual.
- Revisa `manifests/` antes de hacer `git push` — es información pública sobre lo que tienes instalado.
