#!/usr/bin/env python3
"""Run the Laravel contract check without changing the repository or user databases."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def run(command, cwd, env=None):
    result = subprocess.run(command, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        sys.stderr.write(result.stdout + result.stderr)
        raise SystemExit(result.returncode)
    return result.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--autoload', type=Path, help='Existing Composer autoload.php with illuminate/database 13.0.0; otherwise install in a temporary directory')
    args = parser.parse_args()
    source = Path(__file__).resolve().parent
    repo = source.parent.parent
    with tempfile.TemporaryDirectory(prefix='hxwell-laravel-') as directory:
        work = Path(directory)
        autoload = args.autoload.resolve() if args.autoload else work / 'vendor/autoload.php'
        if not args.autoload:
            shutil.copy(source / 'composer.json', work)
            env = dict(os.environ, COMPOSER_HOME=str(work / 'composer-home'), COMPOSER_CACHE_DIR=str(work / 'composer-cache'))
            print('Installing the pinned Laravel database component in a temporary directory...', flush=True)
            run(['composer', 'install', '--no-interaction', '--no-plugins', '--no-scripts', '--prefer-dist'], work, env)
        (work / 'resources/views').mkdir(parents=True)
        hxml = (repo / 'tests/unit/build.hxml').read_text()
        hxml = hxml.replace('-cp ../../src', f'-cp {repo}/src').replace('-cp src', f'-cp {source}')
        hxml = hxml.replace('-main TestMain', '-main SchemaCompatibility')
        (work / 'compat.hxml').write_text(hxml)
        extra = ['-lib', 'hx4compat'] if int(run(['haxe', '--version'], work).split('.')[0]) >= 5 else []
        print('Compiling schema scenarios on JVM and PHP...', flush=True)
        run(['haxe', 'compat.hxml', *extra, '-lib', 'hxjava', '--jvm', 'schema.jar'], work)
        (work / 'jvm.json').write_text(run(['java', '-jar', 'schema.jar'], work))
        run(['haxe', 'compat.hxml', *extra, '--php', 'php'], work)
        (work / 'php.json').write_text(run(['php', 'php/index.php'], work))
        (work / 'laravel.json').write_text(run(['php', str(source / 'reference.php'), str(autoload)], work))
        print(run([sys.executable, str(source / 'compare.py'), 'jvm.json', 'php.json', 'laravel.json'], work).strip())


if __name__ == '__main__':
    main()
