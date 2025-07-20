<?php
if (!chdir('..')) {
	throw new \Exception("chdir failed!");
}

require __DIR__.'/../hxwell.boot.php';