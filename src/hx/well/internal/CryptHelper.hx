package hx.well.internal;

#if force_haxe_crypto
typedef CryptHelper = HaxeAesHelper;
#elseif jvm
typedef CryptHelper = JavaAesHelper;
#elseif php
typedef CryptHelper = PhpAesHelper;
#else
typedef CryptHelper = HaxeAesHelper;
#end