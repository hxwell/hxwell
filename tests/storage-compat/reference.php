<?php
require $argv[1];
if (Composer\InstalledVersions::getVersion('illuminate/filesystem') !== '13.0.0.0') {
    throw new RuntimeException('This comparison requires illuminate/filesystem 13.0.0.');
}

use Illuminate\Container\Container;
use Illuminate\Config\Repository;
use Illuminate\Filesystem\FilesystemManager;

$app = new Container;
$app['config'] = new Repository(['filesystems' => [
    'default' => 'local',
    'disks' => [
        'local' => ['driver' => 'local', 'root' => $argv[2], 'url' => 'https://files.example.test/storage', 'throw' => false, 'report' => false],
        'scoped' => ['driver' => 'scoped', 'disk' => 'local', 'prefix' => 'tenants/one'],
        'readonly' => ['driver' => 'local', 'root' => $argv[2], 'read-only' => true, 'throw' => false, 'report' => false],
    ],
]]);
$manager = new FilesystemManager($app);
$disk = $manager->disk();
$result = [];
$result['text'] = [
    'put' => $disk->put('notes.txt', 'middle'),
    'prepend' => $disk->prepend('notes.txt', 'first', '|'),
    'append' => $disk->append('notes.txt', 'last', '|'),
    'content' => $disk->get('notes.txt'),
    'size' => $disk->size('notes.txt'),
    'exists' => $disk->exists('notes.txt'),
    'missing' => $disk->missing('absent.txt'),
    'absent' => $disk->get('absent.txt'),
];
$disk->put('empty.txt', '');
$disk->append('empty.txt', 'line', '|');
$result['empty_append'] = $disk->get('empty.txt');
$disk->put('orders.json', '{"id":42,"items":["one","two"]}');
$result['json'] = $disk->json('orders.json');
$disk->put('invalid.json', '{');
$result['invalid_json'] = $disk->json('invalid.json');
$stream = fopen('php://temp', 'w+b');
fwrite($stream, hex2bin('0001ff807f0d0a00'));
rewind($stream);
$result['stream_write'] = $disk->writeStream('binary.bin', $stream);
fclose($stream);
$input = $disk->readStream('binary.bin');
$result['stream_hex'] = bin2hex(stream_get_contents($input));
fclose($input);
$result['checksum'] = $disk->checksum('binary.bin');
$result['copy'] = $disk->copy('notes.txt', 'copies/first.txt');
$result['move'] = $disk->move('copies/first.txt', 'archive/final.txt');
$result['original_missing'] = $disk->missing('copies/first.txt');
$disk->makeDirectory('empty-dir');
$disk->put('archive/sub/nested.txt', 'nested');
$result['files'] = $disk->files();
$result['all_files'] = $disk->allFiles();
$result['directory_files'] = $disk->allFiles('archive');
$result['directories'] = $disk->directories();
$result['all_directories'] = $disk->allDirectories();
$result['directory_checks'] = [$disk->exists('empty-dir'), $disk->directoryExists('empty-dir'), $disk->fileExists('empty-dir')];
$disk->put('private.txt', 'private', 'private');
$disk->put('public.txt', 'public', 'public');
$result['visibility'] = [$disk->getVisibility('private.txt'), $disk->getVisibility('public.txt')];
$result['set_visibility'] = $disk->setVisibility('private.txt', 'public');
$result['changed_visibility'] = $disk->getVisibility('private.txt');
$result['metadata'] = [
    'size' => $disk->size('binary.bin'),
    'modified_in_seconds' => $disk->lastModified('binary.bin') > time() - 60,
    'text_mime' => $disk->mimeType('notes.txt'),
    'json_mime' => $disk->mimeType('orders.json'),
];
$result['url'] = $disk->url('folder/file.txt');
$scoped = $manager->disk('scoped');
$result['scoped'] = [
    'put' => $scoped->put('sub/file.txt', 'scoped'),
    'content' => $scoped->get('sub/file.txt'),
    'parent_content' => $disk->get('tenants/one/sub/file.txt'),
    'files' => $scoped->allFiles(),
    'directories' => $scoped->allDirectories(),
    'url' => $scoped->url('sub/file.txt'),
];
$readOnly = $manager->disk('readonly');
$result['readonly'] = [
    'content' => $readOnly->get('notes.txt'),
    'put' => $readOnly->put('blocked.txt', 'blocked'),
    'delete' => $readOnly->delete('notes.txt'),
    'copy' => $readOnly->copy('notes.txt', 'blocked-copy.txt'),
    'move' => $readOnly->move('notes.txt', 'blocked-move.txt'),
    'mkdir' => $readOnly->makeDirectory('blocked-dir'),
    'rmdir' => $readOnly->deleteDirectory('archive'),
    'visibility' => $readOnly->setVisibility('notes.txt', 'public'),
];
$result['delete_many'] = $disk->delete(['notes.txt', 'missing.txt']);
$result['deleted_missing'] = $disk->missing('notes.txt');
$result['delete_directory'] = $disk->deleteDirectory('archive');
$result['deleted_directory_missing'] = $disk->directoryMissing('archive');
$result['delete_absent_directory'] = $disk->deleteDirectory('absent-dir');
$result['failed_copy'] = $disk->copy('missing.txt', 'failed-copy.txt');
echo json_encode($result, JSON_THROW_ON_ERROR), "\n";
