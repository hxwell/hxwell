#!/usr/bin/env python3
"""Compare real HxWell JVM/PHP storage results with pinned Laravel 13."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def run(command, cwd, env):
    result = subprocess.run(command, cwd=cwd, env=env, text=True, capture_output=True, timeout=300)
    if result.returncode:
        raise RuntimeError(f'{command[0]} failed ({result.returncode}):\n{result.stdout}{result.stderr}')
    return result.stdout


def differences(expected, actual, path='$'):
    if isinstance(expected, dict) and isinstance(actual, dict):
        for key in sorted(set(expected) | set(actual)):
            if key not in expected or key not in actual:
                yield f'{path}.{key}: missing or unexpected key'
            else:
                yield from differences(expected[key], actual[key], f'{path}.{key}')
    # Laravel preserves native directory enumeration order; HxWell sorts paths.
    # Compare directory membership without depending on a host filesystem's order.
    elif isinstance(expected, list) and isinstance(actual, list) and path.rsplit('.', 1)[-1] in ('directories', 'all_directories'):
        if sorted(expected) != sorted(actual):
            yield f'{path}: Laravel={expected!r}, HxWell={actual!r}'
    elif expected != actual:
        yield f'{path}: Laravel={expected!r}, HxWell={actual!r}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--autoload', type=Path, help='Existing Composer autoload.php with illuminate/filesystem 13.0.0')
    parser.add_argument('--haxe', default='haxe')
    parser.add_argument('--java', default='java')
    parser.add_argument('--haxelib-path', type=Path, help='Existing isolated .haxelib directory to reuse')
    args = parser.parse_args()
    source = Path(__file__).resolve().parent
    repo = source.parent.parent
    with tempfile.TemporaryDirectory(prefix='hxwell-storage-compat-') as directory:
        work = Path(directory)
        env = dict(os.environ)
        if args.haxelib_path:
            (work / '.haxelib').symlink_to(args.haxelib_path.resolve(), target_is_directory=True)
        autoload = args.autoload.resolve() if args.autoload else work / 'vendor/autoload.php'
        if not args.autoload:
            for name in ('composer.json', 'composer.lock'):
                if (source / name).exists():
                    shutil.copy(source / name, work / name)
            env.update(COMPOSER_HOME=str(work / 'composer-home'), COMPOSER_CACHE_DIR=str(work / 'composer-cache'))
            print('Installing pinned Laravel filesystem dependencies in a temporary directory...', flush=True)
            run(['composer', 'install', '--no-interaction', '--no-plugins', '--no-scripts', '--prefer-dist', '--no-progress'], work, env)
        (work / 'resources/views').mkdir(parents=True)
        hxml = (repo / 'tests/unit/build.hxml').read_text()
        hxml = hxml.replace('-cp ../../src', f'-cp {repo}/src').replace('-cp src', f'-cp {repo}/tests/unit/src\n-cp {source}')
        hxml = hxml.replace('-main TestMain', '-main StorageCompatibility')
        (work / 'compat.hxml').write_text(hxml)
        extra = ['-lib', 'hx4compat'] if int(run([args.haxe, '--version'], work, env).split('.')[0]) >= 5 else []
        print('Compiling JVM and PHP storage scenarios...', flush=True)
        run([args.haxe, 'compat.hxml', *extra, '-lib', 'hxjava', '--jvm', 'storage.jar'], work, env)
        run([args.haxe, 'compat.hxml', *extra, '--php', 'php'], work, env)
        laravel = json.loads(run(['php', str(source / 'reference.php'), str(autoload), str(work / 'laravel-disk')], work, env))
        for target, command in [
            ('JVM', [args.java, '-jar', 'storage.jar', str(work / 'jvm-disk')]),
            ('PHP', ['php', 'php/index.php', str(work / 'php-disk')]),
        ]:
            actual = json.loads(run(command, work, env))
            mismatch = list(differences(laravel, actual))
            if mismatch:
                raise AssertionError(f'{target} contract mismatch:\n' + '\n'.join(mismatch))
            print(f'{target}: all {len(laravel)} storage scenarios match Laravel 13.0.0.', flush=True)


if __name__ == '__main__':
    main()
